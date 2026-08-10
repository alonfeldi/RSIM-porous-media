% compute_global_limits.m
% Author: Alon/ChatGPT
% Purpose: Recursively scan a data folder and compute global min/max over positive values
%          for consistent log-scale visualization across all figures.

% ===== User-configurable options =====
% Candidate variable names to try when loading from MAT/NC files (ordered by priority)
candidateVarNames = {'C','conc','concentration','phi','Phi','data','X'};


% ===== Select root folder =====
rootDir = uigetdir(pwd, 'Select the ROOT data folder to scan');
if rootDir == 0
    error('No folder selected.');
end

% ===== Gather files recursively =====
fileList = {};
extList = {'.mat', '.nc', '.tif', '.tiff'};  % extend as needed
d = dir(rootDir);
stack = d;

while ~isempty(stack)
    item = stack(1); stack(1) = [];
    if item.isdir
        if ~strcmp(item.name, '.') && ~strcmp(item.name, '..')
            sub = dir(fullfile(item.folder, item.name));
            stack = [stack; sub]; %#ok<AGROW>
        end
    else
        [~,~,ext] = fileparts(item.name);
        if any(strcmpi(ext, extList))
            fileList{end+1} = fullfile(item.folder, item.name); %#ok<AGROW>
        end
    end
end

if isempty(fileList)
    error('No data files (.mat/.nc/.tif) found under: %s', rootDir);
end

% ===== Scan all files for values =====
globalMin = +inf;
globalMax = -inf;
filesScanned = 0;

for k = 1:numel(fileList)
    f = fileList{k};
    [~,~,ext] = fileparts(f);
    try
        switch lower(ext)
            case '.mat'
                % Try to load only necessary variable to save memory
                varsInFile = who('-file', f);
                targetVar = '';
                for v = 1:numel(candidateVarNames)
                    if any(strcmp(varsInFile, candidateVarNames{v}))
                        targetVar = candidateVarNames{v};
                        break;
                    end
                end
                if isempty(targetVar)
                    % Fallback: load first numeric array variable
                    s = load(f);
                    fn = fieldnames(s);
                    for t = 1:numel(fn)
                        if isnumeric(s.(fn{t}))
                            X = s.(fn{t});
                            break;
                        end
                    end
                else
                    X = load(f, targetVar); X = X.(targetVar);
                end

            case '.nc'
                info = ncinfo(f);
                % Try candidates; fallback to first non-scalar numeric variable
                X = [];
                for v = 1:numel(candidateVarNames)
                    try
                        X = ncread(f, candidateVarNames{v});
                        break;
                    catch
                    end
                end
                if isempty(X)
                    for vv = 1:numel(info.Variables)
                        dims = info.Variables(vv).Size;
                        if ~isscalar(prod(dims))
                            try
                                tmp = ncread(f, info.Variables(vv).Name);
                                if isnumeric(tmp)
                                    X = tmp; break;
                                end
                            catch
                            end
                        end
                    end
                end
                if isempty(X)
                    warning('No numeric array found in %s. Skipping.', f);
                    continue;
                end

            case {'.tif', '.tiff'}
                X = imread(f);
                X = double(X);

            otherwise
                continue;
        end

        % Flatten, ignore NaN/Inf
        X = X(:);
        X = X(isfinite(X));

        if ~isempty(X)
            localMin = min(X);
            localMax = max(X);
            if localMin < globalMin, globalMin = localMin; end
            if localMax > globalMax, globalMax = localMax; end
            filesScanned = filesScanned + 1;
        end

    catch ME
        warning('Failed to read %s: %s', f, ME.message);
    end
end

if filesScanned == 0
    error('No numeric values found in scanned files.');
end



fprintf('Global min: %.6g\n', globalMin);
fprintf('Global max:          %.6g\n', globalMax);

save('global_limits.mat', 'globalMin', 'globalMax', 'rootDir', 'filesScanned');
disp('Saved global_limits.mat in the selected root folder.');
