function [field, variableName] = loadContaminationField(filePath)
% LOADCONTAMINATIONFIELD Load one dense contamination field from MAT or DAT.
%
% Inputs:
%   filePath     - path to a .mat or whitespace-delimited .dat file.
%
% Outputs:
%   field        - numeric 2-D contamination matrix.
%   variableName - source variable name for MAT files, or 'dat_matrix'.

[~, ~, ext] = fileparts(filePath);
ext = lower(ext);

switch ext
    case '.dat'
        field = load(filePath);
        variableName = 'dat_matrix';

    case '.mat'
        priorityNames = {'X', 'matrixData', 'C', 'conc', 'concentration', ...
                         'data', 'field'};
        varsInFile = who('-file', filePath);
        variableName = '';

        for i = 1:numel(priorityNames)
            if any(strcmp(varsInFile, priorityNames{i}))
                variableName = priorityNames{i};
                loaded = load(filePath, variableName);
                field = loaded.(variableName);
                break;
            end
        end

        if isempty(variableName)
            loaded = load(filePath);
            names = fieldnames(loaded);
            field = [];
            for i = 1:numel(names)
                candidate = loaded.(names{i});
                if isnumeric(candidate) && ismatrix(candidate) && ~isempty(candidate)
                    field = candidate;
                    variableName = names{i};
                    break;
                end
            end
            if isempty(variableName)
                error('No numeric 2-D field found in MAT file: %s', filePath);
            end
        end

    otherwise
        error('Unsupported data extension "%s" for file: %s', ext, filePath);
end

if ~isnumeric(field) || ~ismatrix(field) || isempty(field)
    error('Loaded field is not a non-empty numeric matrix: %s', filePath);
end

field = double(field);
end
