browse_save_userlayout(testData, net);                          % בחירה ידנית + שמירה ל-pwd/paper_figs
% browse_save_userlayout(testData, net, 'SaveDir','outputs_figs'); % שמירה לתיקייה ייעודית


function browse_save_userlayout(ds, net, varargin)
% BROWSE_SAVE_USERLAYOUT  Browse samples from datastore with user's exact tile layout
% Panels per sample:
%   [1] Prediction (with sensors overlay)     | [2] Ground truth (+colorbar)
%   [West] Input sensors vector (Kx1)
%
% Usage:
%   browse_save_userlayout(testData, net);
%   browse_save_userlayout(testData, net, 'SaveDir','paper_figs');
%
% Controls:
%   Buttons: Save, Next, Quit
%   Keys:    S,    N,    Q

% ---- Params ----
p = inputParser;
addParameter(p,'SaveDir','',@(s)ischar(s)||isstring(s));
parse(p,varargin{:});
args = p.Results;

% ---- Files / selection ----
if ~isprop(ds,'Files') || isempty(ds.Files)
    % Count-only fallback (no names)
    reset(ds); N=0; while hasdata(ds), read(ds); N=N+1; end; reset(ds);
    files = string(compose("sample_%03d",1:N));
else
    files = string(ds.Files(:));
end

[listIdx, ok] = listdlg('PromptString','Select samples to review:', ...
                         'ListString', cellstr(files), ...
                         'SelectionMode','multiple', 'ListSize',[440 520]);
if ~ok || isempty(listIdx), disp('No samples selected.'); return; end

% ---- Output dir ----
if isempty(args.SaveDir)
    outDir = fullfile(pwd,'paper_figs');
else
    outDir = char(args.SaveDir);
end
if ~exist(outDir,'dir'), mkdir(outDir); end

% ---- Subset datastore in chosen order ----
reviewDS = subset(ds, listIdx);
reset(reviewDS);

% ---- Main loop ----
fig = [];
while hasdata(reviewDS)
    X = read(reviewDS);                    % {sensorVec, Xfull, sensorsK}
    v      = X{1}(:);
    Xtrue  = X{2};
    sensK  = X{3};
    K      = numel(v);

    Xmin = scallingCorrection(min(Xtrue(:)));
    Xmax = scallingCorrection(max(Xtrue(:))) + 1e-16;

    % Prediction
    ypred = predict(net, reshape(v,[K 1 1]));

    % ---- Figure: ----
    if isempty(fig) || ~isvalid(fig)
        fig = figure('Name','Model predictions','Color','w','Position',[80 80 650 520]);
    else
        clf(fig);
    end
    tl = tiledlayout(fig, 1, 2, "Padding","tight","TileSpacing","none");

    % Tile 1: Prediction (+sensors)
    nexttile;
    imagesc(scallingCorrection(ypred), [Xmin Xmax]); hold on;
    if ~isempty(sensK)
        scatter(sensK(:,2), sensK(:,1), 25, 'w', 'filled', 'MarkerEdgeColor','k', 'LineWidth',1);
    end
    title(sprintf('Prediction (corr=%.3f)', mat_corr(Xtrue, ypred)));
    axis image off; hold off;

    % Tile 2: Ground truth (+colorbar)
    nexttile;
    imagesc(scallingCorrection(Xtrue), [Xmin Xmax]);
    title('Ground truth (+sensors)'); colorbar; axis image off;

    % WEST tile: input sensors vector (Kx1)
    nexttile('West');
    imagesc(scallingCorrection(reshape(v,[K,1])), [Xmin Xmax]);
    title('Input sensors'); axis off;

    % ---- UI panel (Save / Next / Quit) ----
    u = uipanel(fig,'Position',[0 0 1 0.12],'BorderType','none');
    uicontrol(u,'Style','pushbutton','String','Save (S)','Units','normalized', ...
        'Position',[0.30 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','save'));
    uicontrol(u,'Style','pushbutton','String','Next (N)','Units','normalized', ...
        'Position',[0.48 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','next'));
    uicontrol(u,'Style','pushbutton','String','Quit (Q)','Units','normalized', ...
        'Position',[0.66 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','quit'));

    set(fig,'WindowKeyPressFcn',@(src,ev) on_key(fig, ev));

    uiwait(fig);
    dec = getappdata(fig,'decision'); setappdata(fig,'decision','');
    if isempty(dec), dec = 'next'; end

    % Determine a safe filename stem
    curIdx = listIdx(1); listIdx(1) = [];  % pop front for name
    baseName = safe_name(files(curIdx));

    switch dec
        case 'save'
            outPng = fullfile(outDir, sprintf('panel_%s.png', baseName));
            exportgraphics(fig, outPng, 'Resolution', 220);
            fprintf('Saved: %s\n', outPng);
        case 'quit'
            if isvalid(fig), close(fig); end
            fprintf('Quit browsing. Images (if saved) are in: %s\n', outDir);
            return;
        case 'next'
            % continue to next sample
    end

    drawnow;
end

if isvalid(fig), close(fig); end
fprintf('Done. Images (if saved) are in: %s\n', outDir);
end

% ---------- helpers ----------
function on_key(fig, ev)
    switch lower(ev.Key)
        case 's', setappdata(fig,'decision','save');
        case 'n', setappdata(fig,'decision','next');
        case 'q', setappdata(fig,'decision','quit');
    end
    uiresume(fig);
end

function c = mat_corr(A,B)
    A = A - mean(A,"all");
    B = B - mean(B,"all");
    c = sum(A(:).*B(:)) / (norm(A(:))*norm(B(:)) + 1e-12);
end

function nm = safe_name(fp)
    s = char(fp);
    [~,n,e] = fileparts(s);
    nm = regexprep([n e], '[^\w\d\-]+','_');
end

function x = scallingCorrection(x,t)
    if nargin < 2, t = 10; end
    x = x .* (x >= t);
    x = log10(x);
end
