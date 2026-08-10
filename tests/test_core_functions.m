% TEST_CORE_FUNCTIONS Lightweight smoke test for the publication workflow.

clear; clc;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'code')));

cfg = defaultRsimConfig();
cfg.noiseFraction = 0;

data = loadExampleDataset(fullfile(repoRoot, 'examples', 'data', ...
                                   'rsim_porous_media_demo.mat'));
fields = data.contamination_fields;

assert(ndims(fields) == 3, 'Expected H x W x N fields.');
assert(size(data.sensor_locations, 2) == 2, 'Expected [row, col] sensors.');

entropyMap = computeEntropyMap(fields, cfg.entropyBins);
assert(isequal(size(entropyMap), [size(fields, 1), size(fields, 2)]), ...
       'Entropy map size mismatch.');

sensorLocations = data.sensor_locations(1:cfg.sensorCount, :);
sensorValues = extractSensorMeasurements(fields, sensorLocations, ...
                                         cfg.noiseFraction, cfg.randomSeed);
assert(isequal(size(sensorValues), [size(fields, 3), cfg.sensorCount]), ...
       'Sensor value size mismatch.');

idx = splitDatasetIndices(size(fields, 3), cfg.splitFractions, cfg.randomSeed);
model = trainLinearRsimDecoder(sensorValues(idx.train, :), fields(:, :, idx.train), ...
                               'RidgeLambda', cfg.ridgeLambda, ...
                               'UseBias', cfg.useBias);
predicted = predictLinearRsimDecoder(model, sensorValues(idx.test, :));
[metrics, summary] = evaluateReconstruction(fields(:, :, idx.test), predicted);

assert(all(isfinite(metrics.rmse)), 'RMSE contains non-finite values.');
assert(all(isfinite(metrics.correlation)), 'Correlation contains non-finite values.');
assert(isfinite(summary.meanRmse), 'Summary RMSE is non-finite.');
assert(isfinite(summary.meanCorrelation), 'Summary correlation is non-finite.');

fprintf('Core smoke test passed with %d held-out samples. Mean corr = %.4f, mean RMSE = %.4f.\n', ...
        numel(idx.test), summary.meanCorrelation, summary.meanRmse);
