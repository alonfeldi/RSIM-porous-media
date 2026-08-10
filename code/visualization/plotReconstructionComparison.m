function fig = plotReconstructionComparison(trueField, predictedField, ...
                                            sensorLocations, outPath)
% PLOTRECONSTRUCTIONCOMPARISON Plot ground truth, RSIM prediction, and error.
%
% Inputs:
%   trueField       - H x W ground-truth contamination field.
%   predictedField  - H x W reconstructed field.
%   sensorLocations - K x 2 [row, col] sensor coordinates.
%   outPath         - optional PNG output path.

if nargin < 4
    outPath = '';
end

trueField = double(trueField);
predictedField = double(predictedField);
err = predictedField - trueField;
clim = [min(trueField(:)), max(trueField(:)) + 1e-16];

fig = figure('Color', 'w', 'Name', 'RSIM reconstruction comparison', ...
             'Position', [100 100 1200 420]);
tiledlayout(fig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile;
imagesc(trueField, clim);
axis image off;
title('Ground truth');
colorbar;
hold on;
scatter(sensorLocations(:, 2), sensorLocations(:, 1), 20, 'w', 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 0.75);
hold off;

nexttile;
imagesc(predictedField, clim);
axis image off;
title(sprintf('RSIM prediction, corr %.3f', matrixCorrelation(trueField, predictedField)));
colorbar;
hold on;
scatter(sensorLocations(:, 2), sensorLocations(:, 1), 20, 'w', 'filled', ...
        'MarkerEdgeColor', 'k', 'LineWidth', 0.75);
hold off;

nexttile;
imagesc(err);
axis image off;
title(sprintf('Prediction error, RMSE %.3g', sqrt(mean(err(:) .^ 2))));
colorbar;

if ~isempty(outPath)
    outDir = fileparts(outPath);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    exportgraphics(fig, outPath, 'Resolution', 220);
end
end
