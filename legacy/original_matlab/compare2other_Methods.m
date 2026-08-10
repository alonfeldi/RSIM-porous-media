compare2otherMethods(testData,'Net', net);

function compare2otherMethods(ds, varargin)
%COMPARE_ON_DATASTORE  Visual + numeric comparison ON AN EXISTING DATASTORE (e.g., testData).
%
% Usage:
%   compare2otherMethods(testData, ...
%       'SaveDir','outputs_test', ...
%       'Layout','2x4', ...
%       'Net', net);   % optional RSIM net
%
% Assumptions on ds.read():
%   Each read(ds) returns a 1x3 cell: {sensorVec (Kx1x1), Xfull (HxW), sensorsK (Kx2)}
%
% Parameters:
%   'SaveDir'   : output folder. If empty -> defaults to pwd/outputs_test.
%                 Saves a panels PNG per chosen sample and 2 CSVs:
%                 summary_metrics_TEST.csv, per_file_metrics_TEST.csv
%   'Layout'    : '2x4' (default) or '4x2' panel arrangement
%   'Net'       : trained network (optional). If provided, adds "RSIM" panel via predict(net, sensorVec)
%
% Notes:
%   - PyKrige panes (UK/OK) are optional via MATLAB-Python bridge (wrapped in try/catch).
%   - Keyboard: [S] Save  [N] Next  [Q] Quit  (Quit = stop showing figures, keep computing + CSV)

% -------- Parse inputs --------
p = inputParser;
addParameter(p,'SaveDir','',              @(s)ischar(s)||isstring(s));
addParameter(p,'Layout','2x4',            @(s)ischar(s)||isstring(s));
addParameter(p,'Net',[],                  @(x)true);
parse(p, varargin{:});
args = p.Results;

% -------- Outputs (with sensible defaults) --------
if isempty(args.SaveDir)
    outDir = fullfile(pwd,'outputs_test');
else
    outDir = char(args.SaveDir);
end
if ~exist(outDir,'dir'), mkdir(outDir); end
pnlDir = fullfile(outDir,'panels'); if ~exist(pnlDir,'dir'), mkdir(pnlDir); end

% -------- Methods and alloc --------
methodNames = {'Linear','Natural','Nearest','IDW','UK','OK','RSIM'};
hasNet = ~isempty(args.Net);
if ~hasNet
    methodNames(end) = []; % remove RSIM if no net provided
end
M = numel(methodNames);

% Estimate N
if isprop(ds,'Files') && ~isempty(ds.Files)
    N = numel(ds.Files);
else
    N = 0; try reset(ds); while hasdata(ds), read(ds); N = N + 1; end, catch, end
end
RMSE = nan(N,M);
CORR = nan(N,M);
fileNames = repmat("", N, 1);

% -------- Iterate over ds --------
reset(ds);
rng(0);
try shuffle(ds); end  % if supported

interactive = true;  % after 'Q' -> false (no figures), keep computing

for i = 1:N
    S = read(ds);  % {sensorVec, Xfull, sensorsK}
    sensorVec = S{1}(:);
    Xtrue     = S{2};
    sensorsK  = S{3};
    [H,W]     = size(Xtrue);
    Xmin = min(Xtrue(:)); Xmax = max(Xtrue(:)) + 1e-16;

    if isprop(ds,'Files') && numel(ds.Files) >= i
        fileNames(i) = string(ds.Files{i});
    else
        fileNames(i) = sprintf("sample_%03d", i);
    end

    % Coordinates
    Ys = sensorsK(:,1);    % rows
    Xs = sensorsK(:,2);    % cols
    [Xq, Yq]   = meshgrid(1:W, 1:H);
    [X1i, X2i] = meshgrid(1:W, 1:H);

    % ---- Reconstructions ----
    % Linear
    F_lin = scatteredInterpolant(Xs, Ys, sensorVec, 'linear','linear');
    Y_lin = F_lin(Xq, Yq);
    [CORR(i,1), RMSE(i,1)] = metrics_pair(Xtrue, Y_lin);

    % Natural
    F_nat = scatteredInterpolant(Xs, Ys, sensorVec, 'natural','linear');
    Y_nat = F_nat(Xq, Yq);
    [CORR(i,2), RMSE(i,2)] = metrics_pair(Xtrue, Y_nat);

    % Nearest
    F_nn  = scatteredInterpolant(Xs, Ys, sensorVec, 'nearest','nearest');
    Y_nn  = F_nn(Xq, Yq);
    [CORR(i,3), RMSE(i,3)] = metrics_pair(Xtrue, Y_nn);

    % IDW (p=2)
    Fint  = idw([Xs Ys], sensorVec, [X1i(:), X2i(:)]);
    Y_idw = reshape(Fint, H, W);
    [CORR(i,4), RMSE(i,4)] = metrics_pair(Xtrue, Y_idw);

    % Universal Kriging (optional)
    if M >= 5
        Y_uk = nan(H,W);
        try
            Y_uk = UniversalKriging_PyKrige(Xs, Ys, sensorVec, 1:W, 1:H);
            [CORR(i,5), RMSE(i,5)] = metrics_pair(Xtrue, Y_uk);
        catch
            % leave NaN
        end
    end

    % Ordinary Kriging (optional)
    if M >= 6
        Y_ok = nan(H,W);
        try
            Y_ok = OrdinaryKriging_PyKrige(Xs, Ys, sensorVec, 1:W, 1:H);
            [CORR(i,6), RMSE(i,6)] = metrics_pair(Xtrue, Y_ok);
        catch
            % leave NaN
        end
    end

    % RSIM (optional)
    if hasNet
        Y_rsim = predict(args.Net, reshape(sensorVec,[numel(sensorVec) 1 1]));
        [CORR(i,7), RMSE(i,7)] = metrics_pair(Xtrue, Y_rsim);
    end

    % ---- Panel figure + interactive save ----
    if interactive
        fig = figure('Color','w','Position',[80 80 1200 750]);
        switch lower(string(args.Layout))
            case "4x2", rows = 4; cols = 2;
            otherwise,  rows = 2; cols = 4; % default
        end
        tiledlayout(fig, rows, cols, 'TileSpacing','compact','Padding','compact');

        show_panel(Y_lin, Xs, Ys, Xmin, Xmax, sprintf('Linear   r=%.2f', CORR(i,1)));
        show_panel(Y_nat, Xs, Ys, Xmin, Xmax, sprintf('Natural  r=%.2f', CORR(i,2)));
        show_panel(Y_nn,  Xs, Ys, Xmin, Xmax, sprintf('Nearest  r=%.2f', CORR(i,3)));
        show_panel(Y_idw, Xs, Ys, Xmin, Xmax, sprintf('IDW      r=%.2f', CORR(i,4)));

        if M >= 5
            if isnan(CORR(i,5)), ttl5 = 'Universal Kriging (N/A)'; else, ttl5 = sprintf('Universal Kriging  r=%.2f', CORR(i,5)); end
            show_panel(Y_uk,  Xs, Ys, Xmin, Xmax, ttl5);
        end
        if M >= 6
            if isnan(CORR(i,6)), ttl6 = 'Ordinary Kriging (N/A)'; else, ttl6 = sprintf('Ordinary Kriging   r=%.2f', CORR(i,6)); end
            show_panel(Y_ok,  Xs, Ys, Xmin, Xmax, ttl6);
        end
        if hasNet
            ttl7 = sprintf('RSIM     r=%.2f', CORR(i,7));
            show_panel(Y_rsim, Xs, Ys, Xmin, Xmax, ttl7);
        end

        nexttile; imagesc(Xtrue, [Xmin Xmax]); title('Ground truth'); axis image off; colorbar;

        % Interactive: Save/Next/Quit
        action = save_or_next(fig);
        if strcmp(action,'save')
            fname = safe_name(fileNames(i));
            exportgraphics(fig, fullfile(pnlDir, sprintf('panel_%03d_%s.png', i, fname)), 'Resolution', 220);
        elseif strcmp(action,'quit')
            interactive = false;  % stop showing figures; continue computing
        end
        close(fig);
    end
end

% -------- Numeric summary over THIS ds (treated as TEST) --------
validRows = ~all(isnan(RMSE),2);
RMSE = RMSE(validRows,:); CORR = CORR(validRows,:);
fileNames = fileNames(validRows);

meanRMSE = mean(RMSE,1);
meanCORR = mean(CORR,1);
Tsum = table(methodNames(:), meanRMSE(:), meanCORR(:), ...
    'VariableNames', {'Method','Mean_RMSE','Mean_Corr'});
disp('=== TEST-SET SUMMARY (on provided datastore) ==='); disp(Tsum);

Tper = table(fileNames, CORR, RMSE);

% ---- Write CSVs (always, with default location if not provided) ----
writetable(Tsum, fullfile(outDir, 'summary_metrics_TEST.csv'));
writetable(Tper, fullfile(outDir, 'per_file_metrics_TEST.csv'));

fprintf('\nSaved summary CSV: %s\n', fullfile(outDir,'summary_metrics_TEST.csv'));
fprintf('Saved per-file CSV: %s\n', fullfile(outDir,'per_file_metrics_TEST.csv'));
fprintf('Panels (if saved):  %s\n', fullfile(outDir,'panels'));
end % ===== main =====

% ================= Helpers =================

function show_panel(Y, Xs, Ys, Xmin, Xmax, ttl)
    nexttile;
    imagesc(Y, [Xmin Xmax]); hold on;
    if ~any(isnan(Y(:))), scatter(Xs, Ys, 12, 'w', 'filled', 'MarkerEdgeColor','k'); end
    title(ttl); colorbar; axis image off;
end

function act = save_or_next(fig)
% UI buttons + keyboard: [S] Save  [N] Next  [Q] Quit
    act = 'next';
    u = uipanel(fig,'Position',[0 0 1 0.08],'BorderType','none');
    uicontrol(u,'Style','pushbutton','String','Save (S)','Units','normalized', ...
        'Position',[0.25 0.1 0.15 0.8], 'Callback',@(src,ev)setappdata(fig,'decision','save'));
    uicontrol(u,'Style','pushbutton','String','Next (N)','Units','normalized', ...
        'Position',[0.43 0.1 0.15 0.8], 'Callback',@(src,ev)setappdata(fig,'decision','next'));
    uicontrol(u,'Style','pushbutton','String','Quit (Q)','Units','normalized', ...
        'Position',[0.61 0.1 0.15 0.8], 'Callback',@(src,ev)setappdata(fig,'decision','quit'));

    set(fig,'WindowKeyPressFcn',@(src,ev) on_key(fig, ev));
    uiwait(fig);
    d = getappdata(fig,'decision');
    if ~isempty(d), act = d; end
end

function on_key(fig, ev)
    switch lower(ev.Key)
        case 's', setappdata(fig,'decision','save');
        case 'n', setappdata(fig,'decision','next');
        case 'q', setappdata(fig,'decision','quit');
    end
    uiresume(fig);
end

function fname = safe_name(s)
    s = char(s);
    [~,n,e] = fileparts(s);
    fname = regexprep([n e], '[^\w\d\-]+','_');
end

function [c,r] = metrics_pair(A,B)
    if any(isnan(B(:))) || any(isnan(A(:))), c = NaN; r = NaN; return; end
    A = A - mean(A,"all"); B = B - mean(B,"all");
    c = sum(A(:).*B(:)) / (norm(A(:))*norm(B(:)) + 1e-12);
    D = A - B; r = sqrt(mean(D(:).^2));
end

function Fint = idw(X0,F0,Xint,p,rad,L)
% Inverse Distance Weighting (L-metric): defaults p=2, rad=inf, L=2
    if nargin < 6, L = 2; end
    if nargin < 5, rad = inf; end
    if nargin < 4, p = 2; end
    Q = size(Xint,1);
    Fint = zeros(Q,1);
    for ip = 1:Q
        dx = abs(X0(:,1) - Xint(ip,1)).^L;
        dy = abs(X0(:,2) - Xint(ip,2)).^L;
        D  = (dx + dy).^(1/L);
        D(D==0) = eps; D(D>rad) = inf;
        W = 1 ./ (D.^p);
        Fint(ip) = sum(W.*F0) / sum(W);
    end
end

function Z = UniversalKriging_PyKrige(x,y,z,Xq,Yq)
% Universal Kriging via PyKrige (optional). Requires MATLAB-Python bridge.
    if max(z)-min(z)==0, z(1) = z(1) + 1e-12; end
    Z = pyrun(["from pykrige.uk import UniversalKriging", ...
               "UK = UniversalKriging(x,y,z,variogram_model='linear',drift_terms=['regional_linear'])", ...
               "zgrid, ss = UK.execute('grid', Xq, Yq)"], ...
               "zgrid", x=x, y=y, z=z, Xq=Xq, Yq=Yq);
    Z = double(Z);
end

function Z = OrdinaryKriging_PyKrige(x,y,z,Xq,Yq)
% Ordinary Kriging via PyKrige (optional).
    if max(z)-min(z)==0, z(1) = z(1) + 1e-12; end
    Z = pyrun(["from pykrige.ok import OrdinaryKriging", ...
               "OK = OrdinaryKriging(x,y,z,variogram_model='linear',verbose=False,enable_plotting=False)", ...
               "zgrid, ss = OK.execute('grid', Xq, Yq)"], ...
               "zgrid", x=x, y=y, z=z, Xq=Xq, Yq=Yq);
    Z = double(Z);
end
