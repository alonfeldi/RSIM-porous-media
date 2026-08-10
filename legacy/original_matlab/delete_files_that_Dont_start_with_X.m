% Select the root folder (will scan all subfolders recursively)
rootDir = uigetdir(pwd, 'Select the ROOT folder (recursive scan)');
if isequal(rootDir, 0)
    disp('No folder selected. Operation cancelled.');
    return;
end

% Ask the user (UI) for the required filename prefix to KEEP
answer = inputdlg( ...
    {'Enter the filename prefix to KEEP (files NOT starting with this will be deleted):'}, ...
    'Filename Prefix', [1 70], {''});
if isempty(answer)
    disp('No prefix provided. Operation cancelled.');
    return;
end
prefixStr = answer{1};

% Safety: empty prefix would delete everything — block this by default
if isempty(prefixStr)
    warndlg('Empty prefix provided. This would delete ALL files. Operation cancelled.', 'Warning');
    return;
end

% Find all files recursively (exclude directories)
allEntries = dir(fullfile(rootDir, '**', '*'));
allFiles   = allEntries(~[allEntries.isdir]);

% Determine which files DO NOT start with the prefix
names = {allFiles.name};
toDeleteMask = ~startsWith(names, prefixStr);  % case-sensitive; change to startsWith(...,'IgnoreCase',true) if needed
candidates = allFiles(toDeleteMask);

% Confirm with the user
msg = sprintf('About to DELETE %d files that do NOT start with "%s"\nunder:\n%s\n\nProceed?', ...
              numel(candidates), prefixStr, rootDir);
choice = questdlg(msg, 'Confirm Deletion', 'Yes', 'No', 'No');
if ~strcmp(choice, 'Yes')
    disp('User cancelled. No files were deleted.');
    return;
end

% Delete files
deleted = 0; failed = 0;
for i = 1:numel(candidates)
    fpath = fullfile(candidates(i).folder, candidates(i).name);
    try
        delete(fpath);
        fprintf('Deleted: %s\n', fpath);
        deleted = deleted + 1;
    catch ME
        fprintf('FAILED to delete: %s  (%s)\n', fpath, ME.message);
        failed = failed + 1;
    end
end

fprintf('\nDone. Deleted: %d, Failed: %d, Kept: %d\n', deleted, failed, numel(allFiles) - deleted);
