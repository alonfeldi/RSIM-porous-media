function fig = plotEntropySensors(entropyMap, sensorLocations, outPath)
% PLOTENTROPYSENSORS Plot entropy map and selected sensors.
%
% Inputs:
%   entropyMap      - H x W local entropy values.
%   sensorLocations - K x 2 [row, col] sensor coordinates.
%   outPath         - optional PNG output path.

if nargin < 3
    outPath = '';
end

fig = figure('Color', 'w', 'Name', 'Entropy-based sensor placement');
imagesc(entropyMap);
axis image off;
colormap('hot');
colorbar;
title('Local entropy and selected sensors');
hold on;
scatter(sensorLocations(:, 2), sensorLocations(:, 1), 32, 'w', 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 1);
hold off;

if ~isempty(outPath)
    outDir = fileparts(outPath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    exportgraphics(fig, outPath, 'Resolution', 220);
end
end
