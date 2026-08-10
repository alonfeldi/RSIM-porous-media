% RUN_TRAINING Train a linear RSIM decoder on a research dataset.
%
% Put processed .mat or .dat contamination fields under data/processed before
% running this script, or set dataRoot below to another copied dataset folder.
% This script is the full-data analogue of scripts/run_demo.m.

clear; clc; close all;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'code')));

cfg = defaultRsimConfig();
rng(cfg.randomSeed);

dataRoot = fullfile(repoRoot, 'data', 'processed');
if ~exist(dataRoot, 'dir')
    error(['Expected copied research data under %s. ', ...
           'Do not point this script at the original OneDrive folder when ', ...
           'you intend to write outputs into the repository.'], dataRoot);
end

files = listDataFiles(dataRoot, {'.mat', '.dat'});
if isempty(files)
    error('No .mat or .dat files found under: %s', dataRoot);
end

[fields, keptFiles] = loadFieldStack(files, 'MaxFiles', cfg.training.maxFiles);
fprintf('Loaded %d fields from %s.\n', size(fields, 3), dataRoot);

% The full study computes the entropy map from the available simulated
% concentration ensemble, then samples every realization at those locations.
entropyMap = computeEntropyMap(fields, cfg.entropyBins);
sensorLocations = selectSensorsEntropy(entropyMap, cfg.sensorCount, ...
                                       cfg.minRowSeparation, ...
                                       cfg.minColSeparation);
sensorValues = extractSensorMeasurements(fields, sensorLocations, ...
                                         cfg.noiseFraction, cfg.randomSeed);
idx = splitDatasetIndices(size(fields, 3), cfg.splitFractions, cfg.randomSeed);

% The decoder learns concentration-field statistics from simulations. It does
% not receive hydraulic conductivity or other simulator state variables.
model = trainLinearRsimDecoder(sensorValues(idx.train, :), fields(:, :, idx.train), ...
                               'RidgeLambda', cfg.ridgeLambda, ...
                               'UseBias', cfg.useBias);

predictedTestFields = predictLinearRsimDecoder(model, sensorValues(idx.test, :));
[metrics, summary] = evaluateReconstruction(fields(:, :, idx.test), predictedTestFields);

outDir = fullfile(repoRoot, 'results', 'models');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

save(fullfile(outDir, 'linear_rsim_model.mat'), 'model', 'cfg', ...
     'sensorLocations', 'idx', 'keptFiles', 'summary');
writetable(metrics, fullfile(outDir, 'linear_rsim_test_metrics.csv'));

fprintf('\nTraining complete.\n');
fprintf('  Mean correlation: %.4f\n', summary.meanCorrelation);
fprintf('  Mean RMSE:        %.4f\n', summary.meanRmse);
fprintf('  Model directory:  %s\n', outDir);
