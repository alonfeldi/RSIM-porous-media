function data = loadExampleDataset(exampleFile)
% LOADEXAMPLEDATASET Load the small publication demo dataset.
%
% Inputs:
%   exampleFile - optional path to rsim_porous_media_demo.mat.
%
% Outputs:
%   data        - struct with contamination fields, sensors, and metadata.

if nargin < 1 || isempty(exampleFile)
    thisFile = mfilename('fullpath');
    repoRoot = fileparts(fileparts(fileparts(thisFile)));
    exampleFile = fullfile(repoRoot, 'examples', 'data', ...
                           'rsim_porous_media_demo.mat');
end

if ~exist(exampleFile, 'file')
    error('Example dataset not found: %s', exampleFile);
end

S = load(exampleFile);

if isfield(S, 'contamination_fields')
    fields = S.contamination_fields;
elseif isfield(S, 'fields')
    fields = S.fields;
else
    error('Example dataset must contain contamination_fields.');
end

if isfield(S, 'sensor_locations')
    sensorLocations = S.sensor_locations;
elseif isfield(S, 'selectedPixels')
    sensorLocations = S.selectedPixels;
elseif isfield(S, 'sensors')
    sensorLocations = S.sensors;
else
    sensorLocations = [];
end

data = struct();
data.contamination_fields = double(fields);
data.sensor_locations = double(sensorLocations);

if isfield(S, 'sensor_values')
    data.sensor_values = double(S.sensor_values);
elseif ~isempty(sensorLocations)
    data.sensor_values = extractSensorMeasurements(data.contamination_fields, ...
                                                   data.sensor_locations, 0);
else
    data.sensor_values = [];
end

if isfield(S, 'source_files')
    data.source_files = S.source_files;
else
    data.source_files = {};
end

if isfield(S, 'metadata')
    data.metadata = S.metadata;
else
    data.metadata = struct();
end
end
