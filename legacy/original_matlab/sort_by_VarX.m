% Root directory containing all cross_section_runs data
rootDir = 'C:\Users\alonf\OneDrive - Technion\Thesis\yaniv\cross_section_runs\cross_section_runs';

% Dry-run mode: if true, only print planned moves without executing them
DRY_RUN = false;

files = dir(fullfile(rootDir, '**', '*.dat'));
movedCount = 0; skippedCount = 0; errorCount = 0;

for k = 1:numel(files)
    srcFile = fullfile(files(k).folder, files(k).name);

    % Split folder path into parts (robust on Windows)
    parts = strsplit(files(k).folder, filesep);

    % Find the folder matching "Var <number>"
    varIdx = find(~cellfun('isempty', regexp(parts, '^Var\s+\d+$', 'once')), 1, 'last');

    % Ensure directory structure matches: ...\<Pulse>\ <N>\ <Var X>\file
    if isempty(varIdx) || varIdx < 3
        skippedCount = skippedCount + 1;
        fprintf('SKIP: %s (no recognizable Var/Pulse/N structure)\n', srcFile);
        continue;
    end

    pulseIdx = varIdx - 2;  % e.g. "Pulse_Gauss_10"
    numIdx   = varIdx - 1;  % e.g. "10"

    % Build destination path: ...\Var X\Pulse...\N
    destParts = [parts(1:varIdx-3), parts(varIdx), parts(pulseIdx), parts(numIdx)];
    destFolder = fullfile(destParts{:});

    % If already in destination, skip
    if strcmpi(files(k).folder, destFolder)
        skippedCount = skippedCount + 1;
        fprintf('SKIP: %s (already in desired location)\n', srcFile);
        continue;
    end

    % Ensure destination folder exists
    if ~exist(destFolder, 'dir')
        if ~DRY_RUN
            mkdir(destFolder);
        end
    end

    destFile = fullfile(destFolder, files(k).name);

    try
        fprintf('%s -> %s\n', srcFile, destFile);
        if ~DRY_RUN
            movefile(srcFile, destFile);
        end
        movedCount = movedCount + 1;
    catch ME
        errorCount = errorCount + 1;
        warning('FAILED to move "%s": %s', srcFile, ME.message);
    end
end

fprintf('\nDone moving files. Moved: %d, Skipped: %d, Errors: %d\n', movedCount, skippedCount, errorCount);

%% Remove empty folders
if ~DRY_RUN
    allDirs = dir(fullfile(rootDir, '**'));
    allDirs = allDirs([allDirs.isdir]);  % keep only directories
    % Sort by path length in descending order so subfolders are removed first
    [~, sortIdx] = sort(cellfun(@length, {allDirs.folder}), 'descend');
    for d = sortIdx
        thisDir = fullfile(allDirs(d).folder, allDirs(d).name);
        % Skip root folder
        if strcmpi(thisDir, rootDir)
            continue;
        end
        % Remove if empty
        if isempty(dir(fullfile(thisDir, '*'))) || numel(dir(fullfile(thisDir, '*'))) <= 2
            % (<= 2 accounts for '.' and '..' only)
            fprintf('Removing empty folder: %s\n', thisDir);
            try
                rmdir(thisDir);
            catch ME
                warning('Could not remove folder "%s": %s', thisDir, ME.message);
            end
        end
    end
end
