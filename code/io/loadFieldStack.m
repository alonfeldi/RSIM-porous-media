function [fields, keptFiles] = loadFieldStack(filePaths, varargin)
% LOADFIELDSTACK Load many contamination fields into a H x W x N array.
%
% Inputs:
%   filePaths - cell array of MAT/DAT files.
%
% Name-value options:
%   'MaxFiles' - maximum number of files to load.
%
% Outputs:
%   fields    - dense contamination fields, H x W x N.
%   keptFiles - files that were loaded and matched the first field size.

p = inputParser;
addParameter(p, 'MaxFiles', inf, @(x)isnumeric(x) && isscalar(x) && x > 0);
parse(p, varargin{:});
args = p.Results;

if ischar(filePaths) || isstring(filePaths)
    filePaths = cellstr(filePaths);
end

nToRead = min(numel(filePaths), args.MaxFiles);
fields = [];
keptFiles = {};
imageSize = [];

for i = 1:nToRead
    try
        X = loadContaminationField(filePaths{i});
    catch ME
        warning('Skipping unreadable file "%s": %s', filePaths{i}, ME.message);
        continue;
    end

    if isempty(imageSize)
        imageSize = size(X);
        fields = zeros(imageSize(1), imageSize(2), 0);
    end

    if ~isequal(size(X), imageSize)
        warning('Skipping file with size %s; expected %s: %s', ...
                mat2str(size(X)), mat2str(imageSize), filePaths{i});
        continue;
    end

    fields(:, :, end+1) = X; %#ok<AGROW>
    keptFiles{end+1, 1} = filePaths{i}; %#ok<AGROW>
end

if isempty(fields)
    error('No valid contamination fields were loaded.');
end
end
