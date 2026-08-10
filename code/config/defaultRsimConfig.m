function cfg = defaultRsimConfig()
% DEFAULTRSIMCONFIG Return the default RSIM porous-media configuration.
%
% The values here centralize the standard experiment settings used by the
% publication code. Scripts may override these values locally.

cfg.randomSeed = 0;

cfg.sensorCount = 30;
cfg.minRowSeparation = 20;
cfg.minColSeparation = 20;
cfg.entropyBins = 64;

cfg.noiseFraction = 0.10;
cfg.splitFractions = [0.70, 0.10, 0.20];

% Ridge stabilization is used for small example datasets. Set to 0 to use
% the Moore-Penrose pseudoinverse for an unregularized linear decoder.
cfg.ridgeLambda = 1e-6;
cfg.useBias = false;

cfg.training.maxFiles = inf;

cfg.deepLearning.maxEpochs = 300;
cfg.deepLearning.miniBatchSize = 128;
cfg.deepLearning.validationPatience = 50;
cfg.deepLearning.initialLearnRate = 1e-1;
cfg.deepLearning.l2Regularization = 1e-4;
end
