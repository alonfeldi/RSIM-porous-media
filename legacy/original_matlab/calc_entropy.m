% Select directory containing .mat files (recursively scanned)
matDir = uigetdir('', 'Select Directory Containing .mat Files');
if matDir == 0
    disp('No directory selected. Exiting.');
    return;
end

% Get list of .mat files in directory and all subdirectories
matFiles = dir(fullfile(matDir, '**', '*.mat'));
matFiles = matFiles(~[matFiles.isdir]); % Keep only files, remove directories

if isempty(matFiles)
    disp('No .mat files found in the selected directory. Exiting.');
    return;
end

% Load all non-empty matrices into a 3D array
validCount = 0;
keptFiles = [];
matrixStack = [];

for i = 1:numel(matFiles)
    matFilePath = fullfile(matFiles(i).folder, matFiles(i).name);
    try
        S = load(matFilePath);
        fns = fieldnames(S);
        if isempty(fns)
            fprintf('File %s contains no variables. Deleting...\n', matFiles(i).name);
            delete(matFilePath);
            continue;
        end
        Xtmp = S.(fns{1});
    catch
        fprintf('Error loading file: %s. Deleting...\n', matFiles(i).name);
        delete(matFilePath);
        continue;
    end

    % Delete if the matrix is empty (0x0)
    if ismatrix(Xtmp) && all(size(Xtmp) == 0)
        fprintf('File %s contains an empty 0x0 matrix. Deleting...\n', matFiles(i).name);
        delete(matFilePath);
        continue;
    end

    % Accept any non-empty 2D matrix
    if ismatrix(Xtmp)
        if validCount == 0
            [m, n] = size(Xtmp);
            matrixStack = zeros(m, n, 1, 'like', Xtmp);
            matrixStack(:,:,1) = Xtmp;
        else
            % Resize stack if needed
            [mNew, nNew] = size(Xtmp);
            if mNew == m && nNew == n
                matrixStack(:,:,end+1) = Xtmp;
            else
                fprintf('File %s has a different size (%dx%d) - skipped from stack but kept.\n', ...
                    matFiles(i).name, mNew, nNew);
                continue;
            end
        end
        keptFiles(end+1) = i; %#ok<SAGROW>
        validCount = validCount + 1;
    else
        fprintf('File %s is not a 2D matrix. Deleting...\n', matFiles(i).name);
        delete(matFilePath);
    end
end

if validCount == 0
    disp('No valid non-empty matrices found. Exiting.');
    return;
end

% Compute entropy map
entropyMap = zeros(m, n);
numBins = 64;
for row = 1:m
    for col = 1:n
        v = squeeze(matrixStack(row, col, :));
        entropyMap(row, col) = localEntropy(v, numBins);
    end
end

% Display entropy map
figure;
imagesc(entropyMap);
colormap('hot');
colorbar;
title('Entropy Map');

% Sort by entropy
[sortedValues, linearIndices] = sort(entropyMap(:), 'descend');
[rowIdx, colIdx] = ind2sub(size(entropyMap), linearIndices);

%% Get user parameters
prompt = {'Enter number of highest entropy pixels to select:', ...
          'Enter minimum horizontal distance:', ...
          'Enter minimum vertical distance:'};
answer = inputdlg(prompt, 'Selection Parameters', [1 50], {'10', '10', '10'});
if isempty(answer)
    disp('User cancelled input. Exiting.');
    return;
end
numPixels = str2double(answer{1});
minDistH = str2double(answer{2});
minDistV = str2double(answer{3});

% Select top pixels
selectedPixels = [];
for i = 1:length(sortedValues)
    if size(selectedPixels, 1) >= numPixels
        break;
    end
    candidate = [rowIdx(i), colIdx(i)];
    if isempty(selectedPixels) || all(~(abs(selectedPixels(:,1) - candidate(1)) < minDistV & ...
                                        abs(selectedPixels(:,2) - candidate(2)) < minDistH))
        selectedPixels = [selectedPixels; candidate];
    end
end

% Show selected pixels
hold on;
scatter(selectedPixels(:,2), selectedPixels(:,1), 80, 'w', 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
hold off;

%% Save X and sensors back to kept files
for idx = keptFiles
    matFilePath = fullfile(matFiles(idx).folder, matFiles(idx).name);
    S = load(matFilePath);
    fns = fieldnames(S);
    X = S.(fns{1});
    sensors = selectedPixels;
    save(matFilePath, 'X', 'sensors');
    fprintf('Updated file: %s with X and sensors.\n', matFiles(idx).name);
end

disp('Processing complete.');

% Local function
function H = localEntropy(v, numBins)
    v = v(:);
    if isempty(v) || all(~isfinite(v)), H = 0; return; end
    vmax = max(v); vmin = min(v);
    if vmax - vmin < eps(max(1, abs(vmax))), H = 0; return; end
    edges = linspace(vmin, vmax, numBins+1);
    counts = histcounts(v, edges);
    if ~any(counts), H = 0; return; end
    p = counts / sum(counts);
    p = p(p > 0);
    H = -sum(p .* log2(p));
end
