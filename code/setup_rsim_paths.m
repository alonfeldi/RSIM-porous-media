function repoRoot = setup_rsim_paths()
% SETUP_RSIM_PATHS Add the repository MATLAB code folders to the path.
%
% Outputs:
%   repoRoot - absolute path to the repository root.

thisFile = mfilename('fullpath');
codeRoot = fileparts(thisFile);
repoRoot = fileparts(codeRoot);

addpath(genpath(codeRoot));
end
