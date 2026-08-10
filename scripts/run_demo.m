% RUN_DEMO Demonstrate RSIM reconstruction on a small porous-media dataset.
%
% This script loads a compact example dataset, selects sensors from local
% entropy, trains a linear RSIM decoder, reconstructs held-out fields, and
% writes figures/metrics under results/demo.

clear; clc; close all;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'code')));

cfg = defaultRsimConfig();
rng(cfg.randomSeed);

exampleFile = fullfile(repoRoot, 'examples', 'data', ...
                       'rsim_porous_media_demo.mat');
data = loadExampleDataset(exampleFile);
fields = data.contamination_fields;

fprintf('Loaded demo dataset: %d x %d grid, %d realizations.\n', ...
        size(fields, 1), size(fields, 2), size(fields, 3));

entropyMap = computeEntropyMap(fields, cfg.entropyBins);
if size(data.sensor_locations, 1) >= cfg.sensorCount
    sensorLocations = data.sensor_locations(1:cfg.sensorCount, :);
else
    sensorLocations = selectSensorsEntropy(entropyMap, cfg.sensorCount, ...
                                           cfg.minRowSeparation, ...
                                           cfg.minColSeparation);
end

sensorValues = extractSensorMeasurements(fields, sensorLocations, ...
                                         cfg.noiseFraction, cfg.randomSeed);

idx = splitDatasetIndices(size(fields, 3), cfg.splitFractions, cfg.randomSeed);
model = trainLinearRsimDecoder(sensorValues(idx.train, :), fields(:, :, idx.train), ...
                               'RidgeLambda', cfg.ridgeLambda, ...
                               'UseBias', cfg.useBias);

predictedTestFields = predictLinearRsimDecoder(model, sensorValues(idx.test, :));
[metrics, summary] = evaluateReconstruction(fields(:, :, idx.test), predictedTestFields);

outDir = fullfile(repoRoot, 'results', 'demo');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

writetable(metrics, fullfile(outDir, 'demo_metrics.csv'));
save(fullfile(outDir, 'linear_rsim_demo_model.mat'), 'model', 'cfg', ...
     'sensorLocations', 'idx', 'summary');

plotEntropySensors(entropyMap, sensorLocations, ...
                   fullfile(outDir, 'demo_entropy_sensors.png'));

plotReconstructionComparison(fields(:, :, idx.test(1)), predictedTestFields(:, :, 1), ...
                             sensorLocations, ...
                             fullfile(outDir, 'demo_reconstruction.png'));

fprintf('\nDemo metrics over %d held-out fields:\n', numel(idx.test));
fprintf('  Mean correlation: %.4f\n', summary.meanCorrelation);
fprintf('  Mean RMSE:        %.4f\n', summary.meanRmse);
fprintf('  Mean rel. RMSE:   %.4f\n', summary.meanRelativeRmse);
fprintf('\nWrote demo outputs to: %s\n', outDir);
