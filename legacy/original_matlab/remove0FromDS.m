% Usage:
reset(testData);
[testData, removedIdx, removedFiles] = remove0fromDS(testData);

function [ds, removedIdx, removedFiles] = remove0fromDS(ds)
%REMOVE0FROMDS keep only files whose X{1,2} is NOT all zeros.
% Does NOT delete files from disk; only filters ds.Files.
%
% Returns:
%   ds            - the filtered datastore
%   removedIdx    - indices of removed files in the original ds.Files
%   removedFiles  - paths of removed files

    % Basic sanity check
    assert(isprop(ds,'Files') && isprop(ds,'ReadFcn'), ...
        'This function expects a FileDatastore-like object with Files and ReadFcn.');

    files = ds.Files;
    keep  = true(numel(files),1);
    removedIdx = [];

    % Loop over files explicitly using the datastore's ReadFcn
    for i = 1:numel(files)
        Xi = ds.ReadFcn(files{i});  % Read current file contents

        % Extract the second variable/vector:
        % Support common cases: table with 1 row & 2 columns, or cell array
        if istable(Xi)
            assert(width(Xi) >= 2 && height(Xi) >= 1, ...
                'Expected at least 1x2 table from ReadFcn.');
            v = Xi{1,1};
        elseif iscell(Xi)
            assert(numel(Xi) >= 2, 'Expected at least 2 elements in cell output.');
            v = Xi{1,1};
        else
            error('Unsupported ReadFcn output type: %s', class(Xi));
        end

        % Decide if "all zeros"
        isAllZero = (isnumeric(v) || islogical(v)) && ~any(v(:));

        if isAllZero
            keep(i) = false;
            removedIdx(end+1,1) = i; %#ok<AGROW>
        end
    end

    removedFiles = files(~keep);
    ds.Files     = files(keep);  % filter datastore (no deletion)
    reset(ds);                   % ready for reading

    % Optional: print a short summary
    fprintf('Kept %d files, removed %d files with X{:,1} all zeros.\n', ...
            nnz(keep), nnz(~keep));
end
