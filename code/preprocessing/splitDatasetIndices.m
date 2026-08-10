function idx = splitDatasetIndices(numSamples, splitFractions, randomSeed)
% SPLITDATASETINDICES Create reproducible train/validation/test indices.
%
% Inputs:
%   numSamples     - number of realizations.
%   splitFractions - [train, validation, test] fractions summing to 1.
%   randomSeed     - optional random seed.
%
% Outputs:
%   idx            - struct with train, validation, and test index vectors.

if nargin < 2 || isempty(splitFractions)
    splitFractions = [0.70, 0.10, 0.20];
end
if nargin >= 3 && ~isempty(randomSeed)
    rng(randomSeed);
end

if numel(splitFractions) ~= 3 || abs(sum(splitFractions) - 1) > 1e-9
    error('splitFractions must contain three values that sum to 1.');
end

order = randperm(numSamples);
nTrain = round(splitFractions(1) * numSamples);
nVal = round(splitFractions(2) * numSamples);

nTrain = min(nTrain, numSamples);
nVal = min(nVal, numSamples - nTrain);

idx = struct();
idx.train = order(1:nTrain);
idx.validation = order(nTrain + 1:nTrain + nVal);
idx.test = order(nTrain + nVal + 1:end);
end
