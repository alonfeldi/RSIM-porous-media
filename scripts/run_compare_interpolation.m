% RUN_COMPARE_INTERPOLATION Compare RSIM with classical interpolation methods.
%
% The comparison mirrors the original MATLAB scripts at a small demo scale:
% Linear, Natural, Nearest, IDW, and RSIM. Kriging through PyKrige remains in
% the legacy scripts because it depends on the local MATLAB-Python bridge.
% The full paper also reports kriging baselines from the original run.

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

sampleIndex = idx.test(1);
truth = fields(:, :, sampleIndex);
z = sensorValues(sampleIndex, :);

% RSIM uses the learned decoder; the baseline methods use only the same sparse
% sensor values and deterministic interpolation assumptions.
rsimPrediction = predictLinearRsimDecoder(model, z);

[comparisonMetrics, predictions] = compareInterpolationMethods(truth, ...
    sensorLocations, z, 'RsimPrediction', rsimPrediction);

outDir = fullfile(repoRoot, 'results', 'demo');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

writetable(comparisonMetrics, fullfile(outDir, 'interpolation_comparison.csv'));
save(fullfile(outDir, 'interpolation_comparison_predictions.mat'), ...
     'predictions', 'comparisonMetrics', 'sensorLocations', 'sampleIndex');

disp(comparisonMetrics);
fprintf('Wrote interpolation comparison outputs to: %s\n', outDir);
