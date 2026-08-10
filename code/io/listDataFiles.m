function files = listDataFiles(rootDir, extensions)
% LISTDATAFILES Recursively list data files below a root directory.
%
% Inputs:
%   rootDir    - directory to scan.
%   extensions - cell array such as {'.mat', '.dat'}.
%
% Outputs:
%   files      - sorted cell array of absolute file paths.

if nargin < 2 || isempty(extensions)
    extensions = {'.mat', '.dat'};
end
if ischar(extensions) || isstring(extensions)
    extensions = cellstr(extensions);
end

for i = 1:numel(extensions)
    ext = char(extensions{i});
    if isempty(ext) || ext(1) ~= '.'
        ext = ['.' ext];
    end
    extensions{i} = lower(ext);
end

if ~exist(rootDir, 'dir')
    error('Data root does not exist: %s', rootDir);
end

entries = dir(fullfile(rootDir, '**', '*'));
entries = entries(~[entries.isdir]);

files = {};
for i = 1:numel(entries)
    [~, ~, ext] = fileparts(entries(i).name);
    if any(strcmpi(lower(ext), extensions))
        files{end+1, 1} = fullfile(entries(i).folder, entries(i).name); %#ok<AGROW>
    end
end

files = sort(files);
end
