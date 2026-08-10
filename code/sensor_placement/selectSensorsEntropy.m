function sensorLocations = selectSensorsEntropy(entropyMap, numSensors, ...
                                                minRowSeparation, minColSeparation)
% SELECTSENSORSENTROPY Select informative sensor locations from entropy.
%
% Selects grid cells in descending entropy order while preserving the
% original spacing rule: a candidate is rejected only if it is closer than
% both the row and column separation thresholds to an already selected cell.
%
% Inputs:
%   entropyMap        - H x W local entropy map.
%   numSensors        - desired number of sensors.
%   minRowSeparation  - minimum vertical spacing in grid cells.
%   minColSeparation  - minimum horizontal spacing in grid cells.
%
% Outputs:
%   sensorLocations   - K x 2 matrix of [row, col] indices.

if nargin < 3 || isempty(minRowSeparation)
    minRowSeparation = 20;
end
if nargin < 4 || isempty(minColSeparation)
    minColSeparation = minRowSeparation;
end

[~, linearIndices] = sort(entropyMap(:), 'descend');
[rowIdx, colIdx] = ind2sub(size(entropyMap), linearIndices);

sensorLocations = zeros(numSensors, 2);
count = 0;

for i = 1:numel(linearIndices)
    if count >= numSensors
        break;
    end

    candidate = [rowIdx(i), colIdx(i)];
    if count == 0
        accept = true;
    else
        selected = sensorLocations(1:count, :);
        tooClose = abs(selected(:, 1) - candidate(1)) < minRowSeparation & ...
                   abs(selected(:, 2) - candidate(2)) < minColSeparation;
        accept = all(~tooClose);
    end

    if accept
        count = count + 1;
        sensorLocations(count, :) = candidate;
    end
end

sensorLocations = sensorLocations(1:count, :);
if count < numSensors
    warning('Selected only %d sensors out of the requested %d.', count, numSensors);
end
end
