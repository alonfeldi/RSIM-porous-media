function [metrics, predictions] = compareInterpolationMethods(trueField, ...
    sensorLocations, sensorValues, varargin)
% COMPAREINTERPOLATIONMETHODS Compare RSIM with classical interpolants.
%
% Inputs:
%   trueField       - H x W dense ground truth.
%   sensorLocations - K x 2 [row, col] sensor coordinates.
%   sensorValues    - K x 1 concentration measurements.
%
% Name-value options:
%   'RsimPrediction' - optional H x W RSIM reconstruction.
%
% Outputs:
%   metrics          - table of RMSE and correlation by method.
%   predictions      - struct containing reconstructed fields.

p = inputParser;
addParameter(p, 'RsimPrediction', [], @(x)isnumeric(x) || isempty(x));
parse(p, varargin{:});
args = p.Results;

trueField = double(trueField);
sensorValues = double(sensorValues(:));
sensorLocations = double(sensorLocations);

[nRows, nCols] = size(trueField);
rows = sensorLocations(:, 1);
cols = sensorLocations(:, 2);
[colGrid, rowGrid] = meshgrid(1:nCols, 1:nRows);

predictions = struct();

F = scatteredInterpolant(cols, rows, sensorValues, 'linear', 'linear');
predictions.Linear = F(colGrid, rowGrid);

F = scatteredInterpolant(cols, rows, sensorValues, 'natural', 'linear');
predictions.Natural = F(colGrid, rowGrid);

F = scatteredInterpolant(cols, rows, sensorValues, 'nearest', 'nearest');
predictions.Nearest = F(colGrid, rowGrid);

predictions.IDW = idwInterpolation(sensorLocations, sensorValues, [nRows, nCols]);

methodNames = {'Linear'; 'Natural'; 'Nearest'; 'IDW'};
fields = {predictions.Linear; predictions.Natural; predictions.Nearest; ...
          predictions.IDW};

if ~isempty(args.RsimPrediction)
    predictions.RSIM = args.RsimPrediction;
    methodNames{end+1, 1} = 'RSIM';
    fields{end+1, 1} = args.RsimPrediction;
end

rmse = zeros(numel(methodNames), 1);
correlation = zeros(numel(methodNames), 1);
for i = 1:numel(methodNames)
    [oneMetric, ~] = evaluateReconstruction(trueField, fields{i});
    rmse(i) = oneMetric.rmse(1);
    correlation(i) = oneMetric.correlation(1);
end

method = methodNames;
metrics = table(method, rmse, correlation);
end
