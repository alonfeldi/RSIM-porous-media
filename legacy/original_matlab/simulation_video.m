% Select directory containing .mat files
matDir = uigetdir('', 'Select Directory Containing .mat Files');
if matDir == 0
    disp('No directory selected. Exiting.');
    return;
end

% Get list of .mat files in directory
matFiles = dir(fullfile(matDir, '*.mat'));

if isempty(matFiles)
    disp('No .mat files found in the selected directory. Exiting.');
    return;
end

% Display each 2D matrix sequentially
figure;
for i = 1:length(matFiles)
    matFilePath = fullfile(matDir, matFiles(i).name);
    
    % Load the .mat file
    try
        loadedData = load(matFilePath);
        fieldNames = fieldnames(loadedData);
        matrixData = loadedData.(fieldNames{1}); % Assuming first field is the matrix
    catch
        fprintf('Error loading file: %s. Skipping.\n', matFiles(i).name);
        continue;
    end
    
    % Check if data is 2D
    if ndims(matrixData) ~= 2
        fprintf('File %s does not contain a 2D matrix. Skipping.\n', matFiles(i).name);
        continue;
    end
    
    % Display matrix
    imagesc(log10(matrixData));
    colormap('jet');
    colorbar;
    title(sprintf('File: %s', matFiles(i).name));
    pause(0.5); % Adjust pause for playback speed
end

disp('Display completed.');