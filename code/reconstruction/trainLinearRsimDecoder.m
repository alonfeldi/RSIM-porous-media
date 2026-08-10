function model = trainLinearRsimDecoder(sensorValues, fields, varargin)
% TRAINLINEARRSIMDECODER Fit a linear RSIM decoder from sparse measurements.
%
% The decoder has the form:
%
%   f_hat(:)' = z * W + b
%
% where z is a sparse sensor vector and f_hat is the reconstructed dense
% contamination field.
%
% Inputs:
%   sensorValues - N x K sparse measurement matrix.
%   fields       - H x W x N dense target fields.
%
% Name-value options:
%   'RidgeLambda' - nonnegative ridge penalty on W. The bias is not penalized.
%   'UseBias'     - true to learn an intercept term.
%
% Outputs:
%   model         - struct with weights, bias, image size, and metadata.
%
% Scientific boundary:
%   This decoder learns only from sparse concentration measurements and dense
%   concentration targets. It intentionally does not accept hydraulic
%   conductivity, flow velocity, or simulator parameters as inputs.

p = inputParser;
addParameter(p, 'RidgeLambda', 0, @(x)isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'UseBias', true, @(x)islogical(x) && isscalar(x));
parse(p, varargin{:});
args = p.Results;

sensorValues = double(sensorValues);
fields = double(fields);

if ndims(fields) == 2
    fields = reshape(fields, size(fields, 1), size(fields, 2), 1);
end

[nRows, nCols, nFields] = size(fields);
if size(sensorValues, 1) ~= nFields
    error('sensorValues must have one row for each field realization.');
end

nSensors = size(sensorValues, 2);
targets = reshape(fields, nRows * nCols, nFields).';

% Each row of design is one sparse measurement vector z_j. Each row of
% targets is the corresponding dense field f_j flattened over Omega.
if args.UseBias
    design = [sensorValues, ones(nFields, 1)];
else
    design = sensorValues;
end

if args.RidgeLambda > 0
    % Ridge is a numerical stabilizer for small demo datasets; it is not a
    % change to the RSIM formulation. The intercept, when used, is unpenalized.
    penalty = eye(size(design, 2));
    if args.UseBias
        penalty(end, end) = 0;
    end
    coefficients = (design.' * design + args.RidgeLambda * penalty) \ ...
                   (design.' * targets);
else
    coefficients = pinv(design) * targets;
end

model = struct();
model.type = 'linear_rsim_decoder';
model.sensorCount = nSensors;
model.imageSize = [nRows, nCols];
model.ridgeLambda = args.RidgeLambda;
model.useBias = args.UseBias;
model.weights = coefficients(1:nSensors, :);
if args.UseBias
    model.bias = coefficients(end, :);
else
    model.bias = zeros(1, nRows * nCols);
end
model.created = datestr(now, 30);
end
