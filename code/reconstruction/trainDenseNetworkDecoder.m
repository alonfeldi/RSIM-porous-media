function net = trainDenseNetworkDecoder(trainData, validationData, imageSize, ...
                                        sensorCount, optionsStruct)
% TRAINDENSENETWORKDECODER Train the original dense fully-connected decoder.
%
% This function preserves the architecture used in the original MATLAB
% research script: a K x 1 sensor vector is mapped by one fully connected
% layer to the flattened image, then reshaped to the contamination grid.
%
% Inputs:
%   trainData      - fileDatastore returning {sensorVec, Xfull, sensorsK}.
%   validationData - validation datastore.
%   imageSize      - [height, width] of the dense contamination field.
%   sensorCount    - number of sensors used by the decoder.
%   optionsStruct  - struct from defaultRsimConfig().deepLearning or similar.
%
% Outputs:
%   net            - trained MATLAB neural network.

if nargin < 5 || isempty(optionsStruct)
    cfg = defaultRsimConfig();
    optionsStruct = cfg.deepLearning;
end

nPixels = prod(imageSize);
layers = [
    imageInputLayer([sensorCount 1 1], 'Name', 'imageinput', 'Normalization', 'none')
    fullyConnectedLayer(nPixels, 'Name', 'fc', ...
        'BiasLearnRateFactor', 0, 'Bias', zeros(nPixels, 1))
    depthToSpace2dLayer(imageSize, 'Name', 'depthToSpace', 'Mode', 'crd')
    regressionLayer('Name', 'regressionoutput')
];

options = trainingOptions('adam', ...
    'MaxEpochs', optionsStruct.maxEpochs, ...
    'MiniBatchSize', optionsStruct.miniBatchSize, ...
    'ValidationData', validationData, ...
    'ValidationPatience', optionsStruct.validationPatience, ...
    'Shuffle', 'every-epoch', ...
    'LearnRateSchedule', 'piecewise', ...
    'InitialLearnRate', optionsStruct.initialLearnRate, ...
    'LearnRateDropPeriod', max(1, round(optionsStruct.maxEpochs / 5)), ...
    'LearnRateDropFactor', 0.5, ...
    'L2Regularization', optionsStruct.l2Regularization, ...
    'Verbose', true, ...
    'OutputNetwork', 'best-validation-loss');

net = trainNetwork(trainData, layers, options);
end
