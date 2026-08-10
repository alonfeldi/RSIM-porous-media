function field = idwInterpolation(sensorLocations, sensorValues, imageSize, ...
                                  power, radius, metricOrder)
% IDWINTERPOLATION Inverse distance weighting over a regular grid.
%
% Inputs:
%   sensorLocations - K x 2 [row, col] sensor coordinates.
%   sensorValues    - K x 1 concentration values.
%   imageSize       - [height, width] output grid.
%   power           - IDW power, default 2.
%   radius          - maximum influence radius, default Inf.
%   metricOrder     - L-p norm order, default 2.

if nargin < 4 || isempty(power)
    power = 2;
end
if nargin < 5 || isempty(radius)
    radius = inf;
end
if nargin < 6 || isempty(metricOrder)
    metricOrder = 2;
end

sensorLocations = double(sensorLocations);
sensorValues = double(sensorValues(:));

[rowGrid, colGrid] = ndgrid(1:imageSize(1), 1:imageSize(2));
query = [rowGrid(:), colGrid(:)];
values = zeros(size(query, 1), 1);

for i = 1:size(query, 1)
    distances = (abs(sensorLocations(:, 1) - query(i, 1)) .^ metricOrder + ...
                 abs(sensorLocations(:, 2) - query(i, 2)) .^ metricOrder) .^ ...
                 (1 / metricOrder);

    exactHit = distances == 0;
    if any(exactHit)
        values(i) = sensorValues(find(exactHit, 1));
        continue;
    end

    distances(distances > radius) = inf;
    weights = 1 ./ (distances .^ power);
    values(i) = sum(weights .* sensorValues) / sum(weights);
end

field = reshape(values, imageSize(1), imageSize(2));
end
