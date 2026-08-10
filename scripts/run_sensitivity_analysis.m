% RUN_SENSITIVITY_ANALYSIS Demo-scale sensitivity to number of sensors.
%
% This small version uses the example dataset. The original workspace also
% contained full result folders named by sensor count; only small summary
% figures from that run are committed under results/figures.
% The paper's sensitivity analysis sets measurement noise to 0% to isolate the
% effect of sensor count; adjust cfg.noiseFraction below if reproducing that
% exact setting with full data.

clear; clc; close all;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'code')));

cfg = defaultRsimConfig();
cfg.noiseFraction = 0;
sensorCounts = [1, 2, 5, 10, 15, 20, 30];

data = loadExampleDataset(fullfile(repoRoot, 'examples', 'data', ...
                                   'rsim_porous_media_demo.mat'));
fields = data.contamination_fields;
entropyMap = computeEntropyMap(fields, cfg.entropyBins);
idx = splitDatasetIndices(size(fields, 3), cfg.splitFractions, cfg.randomSeed);

meanRmse = zeros(numel(sensorCounts), 1);
meanCorrelation = zeros(numel(sensorCounts), 1);

for i = 1:numel(sensorCounts)
    nSensors = sensorCounts(i);

    % Re-select sensors for each sensor count using the same entropy ranking
    % and spacing rule. This measures the information added by each larger
    % sparse sampling layout.
    sensorLocations = selectSensorsEntropy(entropyMap, nSensors, ...
                                           cfg.minRowSeparation, ...
                                           cfg.minColSeparation);
    sensorValues = extractSensorMeasurements(fields, sensorLocations, ...
                                             cfg.noiseFraction, cfg.randomSeed);
    model = trainLinearRsimDecoder(sensorValues(idx.train, :), ...
                                   fields(:, :, idx.train), ...
                                   'RidgeLambda', cfg.ridgeLambda, ...
                                   'UseBias', cfg.useBias);
    predicted = predictLinearRsimDecoder(model, sensorValues(idx.test, :));
    [~, summary] = evaluateReconstruction(fields(:, :, idx.test), predicted);

    meanRmse(i) = summary.meanRmse;
    meanCorrelation(i) = summary.meanCorrelation;
end

sensorCount = sensorCounts(:);
results = table(sensorCount, meanRmse, meanCorrelation);

outDir = fullfile(repoRoot, 'results', 'demo');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
writetable(results, fullfile(outDir, 'sensor_count_sensitivity.csv'));

fig = figure('Color', 'w', 'Name', 'Sensor-count sensitivity');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile;
plot(sensorCount, meanCorrelation, '-o', 'LineWidth', 1.3);
xlabel('Number of sensors');
ylabel('Mean correlation');
grid on;
nexttile;
plot(sensorCount, meanRmse, '-o', 'LineWidth', 1.3);
xlabel('Number of sensors');
ylabel('Mean RMSE');
grid on;
exportgraphics(fig, fullfile(outDir, 'sensor_count_sensitivity.png'), ...
               'Resolution', 220);

disp(results);
fprintf('Wrote sensitivity outputs to: %s\n', outDir);
