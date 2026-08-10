function cfg = defaultRsimConfig()
% DEFAULTRSIMCONFIG Return the default RSIM porous-media configuration.
%
% This file is the single place where manuscript-scale experiment defaults
% are recorded. Keeping these values here avoids scattering scientific
% assumptions such as sensor count, noise level, and train/test split across
% multiple scripts.

cfg.randomSeed = 0;

% Sensor placement settings from the manuscript computation setup.
cfg.sensorCount = 30;
cfg.minRowSeparation = 20;
cfg.minColSeparation = 20;
cfg.entropyBins = 64;

% Sparse measurement uncertainty and dataset splitting.
cfg.noiseFraction = 0.10;
cfg.splitFractions = [0.70, 0.10, 0.20];

% Ridge stabilization is used for small example datasets. Set to 0 to use
% the Moore-Penrose pseudoinverse for an unregularized linear decoder.
cfg.ridgeLambda = 1e-6;

% The manuscript writes the model as W*z + b. The original MATLAB network
% froze the fully-connected bias at zero, so false preserves the original
% computational behavior. Set true only for a deliberate bias-learning run.
cfg.useBias = false;

% Use this to cap local runs on very large copied datasets.
cfg.training.maxFiles = inf;

% Legacy dense-network settings from the original script.
cfg.deepLearning.maxEpochs = 300;
cfg.deepLearning.miniBatchSize = 128;
cfg.deepLearning.validationPatience = 50;
cfg.deepLearning.initialLearnRate = 1e-1;
cfg.deepLearning.l2Regularization = 1e-4;
end
