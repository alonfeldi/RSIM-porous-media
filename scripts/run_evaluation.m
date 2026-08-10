% RUN_EVALUATION Evaluate the demo RSIM decoder workflow.
%
% This script is intentionally lightweight. For full research datasets, use
% scripts/run_training.m and adapt dataRoot to a copied processed dataset.

clear; clc; close all;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'code')));

cfg = defaultRsimConfig();
data = loadExampleDataset(fullfile(repoRoot, 'examples', 'data', ...
                                   'rsim_porous_media_demo.mat'));
fields = data.contamination_fields;

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
writetable(metrics, fullfile(outDir, 'evaluation_metrics.csv'));

disp(metrics);
fprintf('Mean correlation: %.4f\n', summary.meanCorrelation);
fprintf('Mean RMSE: %.4f\n', summary.meanRmse);
