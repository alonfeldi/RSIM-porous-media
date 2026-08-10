function predictedFields = predictLinearRsimDecoder(model, sensorValues)
% PREDICTLINEARRSIMDECODER Reconstruct dense fields with a linear decoder.
%
% Inputs:
%   model        - struct produced by trainLinearRsimDecoder.
%   sensorValues - N x K matrix, or K x 1 vector for a single field.
%
% Outputs:
%   predictedFields - H x W x N reconstructed fields, or H x W for one input.

sensorValues = double(sensorValues);

if isvector(sensorValues)
    sensorValues = sensorValues(:).';
end

if size(sensorValues, 2) ~= model.sensorCount && ...
        size(sensorValues, 1) == model.sensorCount
    sensorValues = sensorValues.';
end

if size(sensorValues, 2) ~= model.sensorCount
    error('Expected %d sensors, received %d.', model.sensorCount, size(sensorValues, 2));
end

nSamples = size(sensorValues, 1);
predictionVectors = sensorValues * model.weights + ...
                    repmat(model.bias, nSamples, 1);

predictedFields = reshape(predictionVectors.', ...
                          model.imageSize(1), model.imageSize(2), nSamples);
if nSamples == 1
    predictedFields = predictedFields(:, :, 1);
end
end
