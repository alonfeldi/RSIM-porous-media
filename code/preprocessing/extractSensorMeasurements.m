function sensorValues = extractSensorMeasurements(fields, sensorLocations, ...
                                                  noiseFraction, randomSeed)
% EXTRACTSENSORMEASUREMENTS Extract sparse concentration measurements.
%
% Inputs:
%   fields          - H x W x N contamination fields.
%   sensorLocations - K x 2 [row, col] 1-based MATLAB indices.
%   noiseFraction   - multiplicative Gaussian noise level, e.g. 0.10.
%   randomSeed      - optional seed for reproducible noise.
%
% Outputs:
%   sensorValues    - N x K matrix, one sparse measurement vector per field.
%
% Paper connection:
%   This is the encoder e(f): it observes the dense field only at the selected
%   sensor locations Omega_s and optionally applies multiplicative Gaussian
%   measurement noise.

if nargin < 3 || isempty(noiseFraction)
    noiseFraction = 0;
end
if nargin >= 4 && ~isempty(randomSeed)
    rng(randomSeed);
end

if ndims(fields) == 2
    fields = reshape(fields, size(fields, 1), size(fields, 2), 1);
end

sensorLocations = double(sensorLocations);
[nRows, nCols, nFields] = size(fields);
nSensors = size(sensorLocations, 1);

if size(sensorLocations, 2) < 2
    error('sensorLocations must be a K x 2 matrix of [row, col] indices.');
end

rows = sensorLocations(:, 1);
cols = sensorLocations(:, 2);
if any(rows < 1) || any(cols < 1) || any(rows > nRows) || any(cols > nCols)
    error('At least one sensor location is outside the field grid.');
end

linearIndices = sub2ind([nRows, nCols], rows, cols);
sensorValues = zeros(nFields, nSensors);

for i = 1:nFields
    field = fields(:, :, i);
    sensorValues(i, :) = field(linearIndices).';
end

if noiseFraction > 0
    % Multiplicative noise follows z = f(omega) * (1 + eta), with
    % eta distributed as zero-mean Gaussian noise.
    sensorValues = sensorValues + ...
        noiseFraction .* randn(size(sensorValues)) .* sensorValues;
end
end
