function entropyMap = computeEntropyMap(fields, numBins)
% COMPUTEENTROPYMAP Compute local Shannon entropy over an ensemble.
%
% Computes the entropy of the simulated concentration distribution at each
% grid cell. High-entropy cells vary strongly across the ensemble and are
% candidate informative sensor locations.
%
% Inputs:
%   fields  - H x W x N contamination fields.
%   numBins - number of histogram bins used at each grid cell.
%
% Outputs:
%   entropyMap - H x W local entropy map.
%
% Paper connection:
%   The entropy map estimates how informative each potential sampling
%   location is across the ensemble of simulated contamination fields.

if nargin < 2 || isempty(numBins)
    numBins = 64;
end

if ndims(fields) == 2
    fields = reshape(fields, size(fields, 1), size(fields, 2), 1);
end

[nRows, nCols, ~] = size(fields);
entropyMap = zeros(nRows, nCols);

for row = 1:nRows
    for col = 1:nCols
        values = squeeze(fields(row, col, :));
        entropyMap(row, col) = localShannonEntropy(values, numBins);
    end
end
end
