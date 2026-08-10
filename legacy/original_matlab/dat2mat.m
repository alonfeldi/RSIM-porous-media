% Select root directory containing multiple subfolders with .dat files
rootDir = uigetdir('', 'Select Root Directory Containing .dat Files');
if rootDir == 0
    disp('No directory selected. Exiting.');
    return;
end

% Select destination root directory for saving .mat files (same folder structure will be kept)
destRootDir = uigetdir('', 'Select Destination Root Directory for .mat Files');
if destRootDir == 0
    disp('No destination directory selected. Exiting.');
    return;
end

% Find all .dat files recursively
datFiles = dir(fullfile(rootDir, '**', '*.dat'));

if isempty(datFiles)
    disp('No .dat files found in the selected directory tree. Exiting.');
    return;
end

% Loop through each .dat file
for i = 1:length(datFiles)
    srcFilePath = fullfile(datFiles(i).folder, datFiles(i).name);

    % Keep relative path from rootDir so we can mirror the folder structure in destRootDir
    relPath = strrep(datFiles(i).folder, rootDir, '');
    destFolder = fullfile(destRootDir, relPath);

    % Make sure destination folder exists
    if ~exist(destFolder, 'dir')
        mkdir(destFolder);
    end

    % Load the .dat file
    try
        matrixData = load(srcFilePath);
    catch
        fprintf('Error loading file: %s. Skipping.\n', srcFilePath);
        continue;
    end

    % Save as .mat with same base name
    [~, name, ~] = fileparts(datFiles(i).name);
    destFilePath = fullfile(destFolder, [name '.mat']);
    save(destFilePath, 'matrixData');

    fprintf('Converted %s -> %s\n', srcFilePath, destFilePath);
end

disp('Recursive conversion completed successfully.');
beep