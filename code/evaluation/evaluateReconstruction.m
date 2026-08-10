function [metrics, summary] = evaluateReconstruction(trueFields, predictedFields)
% EVALUATERECONSTRUCTION Compute reconstruction metrics per realization.
%
% Inputs:
%   trueFields      - H x W x N ground-truth fields.
%   predictedFields - H x W x N reconstructed fields.
%
% Outputs:
%   metrics         - table with RMSE, relative RMSE, and correlation.
%   summary         - struct with mean metrics.
%
% Paper connection:
%   The manuscript reports mean RMSE-style error and mean correlation across
%   test-set realizations. This function exposes both per-sample values and
%   their means.

if ndims(trueFields) == 2
    trueFields = reshape(trueFields, size(trueFields, 1), size(trueFields, 2), 1);
end
if ndims(predictedFields) == 2
    predictedFields = reshape(predictedFields, size(predictedFields, 1), ...
                              size(predictedFields, 2), 1);
end

if ~isequal(size(trueFields), size(predictedFields))
    error('trueFields and predictedFields must have identical sizes.');
end

nSamples = size(trueFields, 3);
rmse = zeros(nSamples, 1);
relativeRmse = zeros(nSamples, 1);
correlation = zeros(nSamples, 1);

for i = 1:nSamples
    truth = trueFields(:, :, i);
    pred = predictedFields(:, :, i);
    diff = truth - pred;
    rmse(i) = sqrt(mean(diff(:) .^ 2));
    valueRange = max(truth(:)) - min(truth(:));
    relativeRmse(i) = rmse(i) / (valueRange + eps);
    correlation(i) = matrixCorrelation(truth, pred);
end

sample = (1:nSamples).';
metrics = table(sample, rmse, relativeRmse, correlation);

summary = struct();
summary.meanRmse = mean(rmse);
summary.meanRelativeRmse = mean(relativeRmse);
summary.meanCorrelation = mean(correlation);
end
