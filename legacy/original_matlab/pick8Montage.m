pick8_montage(trainData, net);  % שמירה לברירת המחדל ./paper_figs/montage.png

function pick8_montage(ds, net, varargin)
% PICK8_MONTAGE  Browse train datastore randomly; pick 8 panels; build 2x4 montage.
% Layout per sample: [Prediction] | [Ground truth (+sensors)]  +  WEST tile: [Input sensors]
%
% Usage:
%   pick8_montage(trainData, net);  % שמירה לברירת מחדל ./paper_figs/montage.png
%   pick8_montage(trainData, net, 'SaveDir','figs', 'OutFile','grid_2x4.png');
%
% Controls per sample window:
%   Buttons:  Choose (C)  |  Next (N)  |  Quit (Q)
%   Keys:     C            |  N         |  Q
%
% Requirements on ds.read():
%   read(ds) -> {sensorVec (Kx1x1), Xfull (HxW), sensorsK (Kx2)}

% ---------- Params ----------
p = inputParser;
addParameter(p,'SaveDir','',@(s)ischar(s)||isstring(s));
addParameter(p,'OutFile','montage.png',@(s)ischar(s)||isstring(s));
parse(p,varargin{:});
args = p.Results;

if isempty(args.SaveDir), outDir = fullfile(pwd,'paper_figs');
else, outDir = char(args.SaveDir);
end
if ~exist(outDir,'dir'), mkdir(outDir); end
outPath = fullfile(outDir, char(args.OutFile));

MAXSEL = 8;                          % נבחר בדיוק 8
pickedRGB = cell(0,1);               % כאן נשמור את התצלומים (RGB) של הפאנלים הנבחרים

% ---------- Randomize DS ----------
reset(ds);
try shuffle(ds); end   

% ---------- Main loop ----------
fig = [];

while hasdata(ds) && numel(pickedRGB) < MAXSEL
    X = read(ds);                     % {sensorVec, Xfull, sensorsK}
    Xtrue  = scallingCorrection(X{2});

    % ----- Figure with user's exact layout -----
    if isempty(fig) || ~isvalid(fig)
        fig = figure('Name','Pick 8 for montage','Color','w','Position',[60 60 400 900]);
    else
        clf(fig);
    end

    imagesc(Xtrue); axis off;

    % --- Control panel (Choose / Next / Quit) ---
    u = uipanel(fig,'Position',[0 0 1 0.12],'BorderType','none');
    uicontrol(u,'Style','pushbutton','String','Choose (C)','Units','normalized', ...
        'Position',[0.30 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','choose'));
    uicontrol(u,'Style','pushbutton','String','Next (N)','Units','normalized', ...
        'Position',[0.48 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','next'));
    uicontrol(u,'Style','pushbutton','String','Quit (Q)','Units','normalized', ...
        'Position',[0.66 0.15 0.15 0.7], 'Callback',@(src,ev)setappdata(fig,'decision','quit'));
    set(fig,'WindowKeyPressFcn',@(src,ev) on_key(fig, ev));

    uiwait(fig);
    dec = getappdata(fig,'decision'); setappdata(fig,'decision','');
    if isempty(dec), dec = 'next'; end

    switch dec
        case 'choose'
            tmpFile = [tempname '.png'];
            try
                exportgraphics(fig, tmpFile, 'BackgroundColor','w', 'Resolution',300);
                pickedRGB{end+1} = imread(tmpFile); %#ok<AGROW>
            catch ME
                warning('exportgraphics failed (%s). Falling back to frame capture.', ME.message);
                fr = getframe(fig); [rgb,~] = frame2im(fr);
                pickedRGB{end+1} = rgb; %#ok<AGROW>
            end
            if exist(tmpFile,'file'), delete(tmpFile); end
            fprintf('Picked %d/%d\n', numel(pickedRGB), MAXSEL);
        case 'quit'
            break; % יציאה בלי להשלים ל-8 (נייצר montage ממה שיש)
        case 'next'
            % פשוט ממשיכים לדוגמה הבאה
    end
end

if ~isempty(fig) && isvalid(fig), close(fig); end

% ---------- Build 2x4 montage (minimal spacing, white background) ----------
if isempty(pickedRGB)
    warning('No images were selected. Montage not created.');
    return;
end

% אם בחרת פחות מ-8, נשלים עם עותקים אחרונים כדי לשמור על 2x4:
while numel(pickedRGB) < 8
    pickedRGB{end+1} = pickedRGB{end}; %#ok<AGROW>
end

% הצגת המונטאז' ושמירה
mFig = figure('Color','w','Position',[100 100 1600 800],'Name','Montage 2x4');
montage(pickedRGB, 'Size',[2 4], 'BorderSize',[1 1], 'BackgroundColor','w'); % רווח מינימלי
axis off; set(gca,'LooseInset',[0 0 0 0]); % לצמצם שוליים
exportgraphics(mFig, outPath, 'Resolution', 300);
close(mFig);

fprintf('Saved montage (2x4) to: %s\n', outPath);
end

% ===== helpers =====
function on_key(fig, ev)
    switch lower(ev.Key)
        case 'c', setappdata(fig,'decision','choose');
        case 'n', setappdata(fig,'decision','next');
        case 'q', setappdata(fig,'decision','quit');
    end
    uiresume(fig);
end

function x = scallingCorrection(x,t)
    if nargin < 2, t = 0; end
    x = x .* (x >= t);
    x = log10(x);
end
