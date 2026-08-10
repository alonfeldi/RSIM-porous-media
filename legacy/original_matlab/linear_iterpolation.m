%% ===================== Vec2Img Training Script (UI + per-file sensors + SVD & Basis) =====================
clear; clc; close all; tic;

%% ---- UI: Select data root (recursively scanned for .mat) ----
dataRoot = uigetdir('', 'Select ROOT folder that contains .mat files (recursive)');
if isequal(dataRoot,0), disp('No data folder selected. Exiting.'); return; end

%% ---- UI: Basic parameters ----
prompt = {'Number of sensors to use (sensorNum):', 'Noise factor (epsilon):', ...
          'Max epochs:', 'Mini-batch size:', 'Validation patience:', ...
          'Train/Val/Test split (e.g. 0.7,0.1,0.2):', 'Initial learn rate:'};
def    = {'10','0','300','128','50','0.7,0.1,0.2','1e-1'};
answ   = inputdlg(prompt, 'Training Parameters', [1 55], def);
if isempty(answ), disp('User cancelled. Exiting.'); return; end

sensorNum          = str2double(answ{1});
epsilon            = str2double(answ{2});
maxEpochs          = str2double(answ{3});
miniBatchSize      = str2double(answ{4});
valPatience        = str2double(answ{5});
splits             = str2num(answ{6}); %#ok<ST2NM>
initLR             = str2double(answ{7});
if numel(splits)~=3 || abs(sum(splits)-1)>1e-9
    error('Split must have 3 numbers summing to 1, e.g., 0.7,0.1,0.2');
end

%% ---- UI: Checkboxes (Display / SVD) ----
respDisp = questdlg('Enable DISPLAY (figures)?', 'Display', 'Yes', 'No', 'Yes');
doDisplay = strcmp(respDisp,'Yes');
% Ask how many samples to display (default 5)
if doDisplay
    ansMax = inputdlg({'How many samples to display (maxDisplay)?:'}, ...
                      'Display Settings', [1 45], {'5'});
    if isempty(ansMax)
        maxDisplay = 5;
    else
        maxDisplay = str2double(ansMax{1});
        if isnan(maxDisplay) || maxDisplay <= 0
            maxDisplay = 5;
        else
            maxDisplay = floor(maxDisplay);
        end
    end
else
    maxDisplay = 0;
end
respSVD  = questdlg('Enable SVD analysis & basis montages?', 'SVD', 'Yes', 'No', 'Yes');
doSVD    = strcmp(respSVD,'Yes');

rng(0);  % reproducibility

%% ---- Gather & filter valid .mat files (must contain X and sensors/selectedPixels) ----
allFiles = dir(fullfile(dataRoot, '**', '*.mat'));
allFiles = allFiles(~[allFiles.isdir]);

validFiles = {};
for i = 1:numel(allFiles)
    fp = fullfile(allFiles(i).folder, allFiles(i).name);
    try
        S = load(fp);
        % Resolve X (full image)
        if isfield(S,'X')
            X = S.X;
        else
            X = []; fns = fieldnames(S);
            for k = 1:numel(fns)
                if ismatrix(S.(fns{k}))
                    X = S.(fns{k}); break;
                end
            end
            if isempty(X), continue; end
        end
        % Resolve sensors
        if isfield(S,'sensors')
            sens = S.sensors;
        elseif isfield(S,'selectedPixels')
            sens = S.selectedPixels;
        else
            continue;
        end
        % At least sensorNum rows of [row col], indices in range
        if size(sens,2) < 2 || size(sens,1) < sensorNum, continue; end
        if any(sens(1:sensorNum,1) < 1) || any(sens(1:sensorNum,2) < 1) ...
           || any(sens(1:sensorNum,1) > size(X,1)) || any(sens(1:sensorNum,2) > size(X,2))
            continue;
        end
        validFiles{end+1} = fp;
    catch
        % skip silently
    end
end

if isempty(validFiles)
    error('No valid .mat files found that contain both X and sensors (>= sensorNum).');
end
fprintf('Using %d valid files out of %d total.\n', numel(validFiles), numel(allFiles));

%% ---- Build datastore over the filtered list ----
readFcn = make_read_func(sensorNum, epsilon);  % returns {sensorVec, Xfull, sensorsK}
ds = fileDatastore(dataRoot, "IncludeSubfolders", true, ...
    "FileExtensions", ".mat", "ReadFcn", readFcn);
ds.Files = validFiles;  % restrict to our validated set

% Split dataset
N = numel(ds.Files);
idx = randperm(N);
nTrain = round(splits(1)*N);
nVal   = round(splits(2)*N);
trainId = idx(1:nTrain);
valId   = idx(nTrain+1 : nTrain+nVal);
testId  = idx(nTrain+nVal+1 : end);
trainData = subset(ds, trainId);
valData   = subset(ds, valId);
testData  = subset(ds, testId);

%% ---- Quick preview (optional) ----
if doDisplay
    reset(testData);
    try
        X = read(testData);  % {sensorVec, Xfull, sensorsK}
        Xmin = min(X{1,2}(:)); Xmax = max(X{1,2}(:))+1e-16;
        figure('Position',[100 100 1200 420]); tiledlayout(1,3,"Padding","compact","TileSpacing","compact");
        nexttile; imagesc(reshape(X{1,1},[sensorNum,1])); title('Sensors vector'); colorbar; axis off;
        nexttile; imagesc(X{1,2},[Xmin Xmax]); title('Example full image'); colorbar; axis image off;
        nexttile; imagesc(X{1,2},[Xmin Xmax]); hold on;
                 scatter(X{1,3}(:,2), X{1,3}(:,1), 25, 'w', 'filled', 'MarkerEdgeColor','k', 'LineWidth',1);
                 title('Sensor positions'); colorbar; axis image off; hold off;
        drawnow;
    catch ME
        warning(ME.identifier, 'Preview failed: %s', ME.message);
    end
end

%% ---- Define network ----
layers = [
    imageInputLayer([sensorNum 1 1], "Name","imageinput", "Normalization","none")
    fullyConnectedLayer(36000, "Name","fc", "BiasLearnRateFactor",0, "Bias",zeros(36000,1))
    depthToSpace2dLayer([300 120], "Name","depthToSpace", "Mode","crd")
    regressionLayer("Name","regressionoutput")
];

%% ---- Training options (quoted names for broad compatibility) ----
options = trainingOptions('adam', ...
    'MaxEpochs',            maxEpochs, ...
    'MiniBatchSize',        miniBatchSize, ...
    'ValidationData',       valData, ...
    'ValidationPatience',   valPatience, ...
    'Shuffle',              'every-epoch', ...
    'LearnRateSchedule',    'piecewise', ...
    'InitialLearnRate',     initLR, ...
    'LearnRateDropPeriod',  max(1, round(maxEpochs/5)), ...
    'LearnRateDropFactor',  0.5, ...
    'L2Regularization',     1e-4, ...
    'Verbose',              true, ...
    'OutputNetwork',        'best-validation-loss'); % add 'Plots','training-progress' if you want

%% ---- Train ----
net = trainNetwork(trainData, layers, options);
beep
%% ---- UI: Save trained net ----
[saveFile, savePath] = uiputfile('trainedVecToImageRegressionNet.mat', 'Save trained network as');
if ~isequal(saveFile,0)
    save(fullfile(savePath, saveFile), "net");
    fprintf('Saved trained net to: %s\n', fullfile(savePath,saveFile));
else
    warning('User skipped saving the network.');
end

%% ---- Evaluate ----
reset(testData);
nT = numel(testData.Files);
corr_list = zeros(nT,1);
rmse_list = zeros(nT,1);
i = 1;
while hasdata(testData)
    X = read(testData);                 % {sensorVec, Xfull, sensorsK}
    ypred = predict(net, X{1,1});
    corr_list(i) = mat_corr(X{1,2}, ypred);
    rmse_list(i) = sqrt(mean((X{1,2}(:) - ypred(:)).^2));  % rmse fallback
    i = i + 1;
end
MCorr = mean(corr_list);
MRMSE = mean(rmse_list);
fprintf('\nSummary\nsensorNum=%d  epsilon=%.4g\nmeanCorr=%.4f  meanRMSE=%.4f\n\n', ...
        sensorNum, epsilon, MCorr, MRMSE);

%% ---- Optional displays ----
if doDisplay && maxDisplay > 0
    % Randomly choose up to maxDisplay samples from testData (shuffle)
    numAvail = numel(testData.Files);
    k = min(maxDisplay, numAvail);
    idxDisp = randperm(numAvail, k);
    dispData = subset(testData, idxDisp);
    % reset(dispData);

    fig = figure('Name','Model predictions');
    for ii = 1:k
        X = read(dispData);  % {sensorVec, Xfull, sensorsK}
        Xmin = min(X{1,2}(:)); Xmax = max(X{1,2}(:)) + 1e-16;

        clf(fig);
        tiledlayout(fig, 1, 2, "Padding","tight","TileSpacing","tight");

        
        nexttile; 
        ypred = predict(net, X{1,1});
        imagesc(ypred, [Xmin Xmax]); hold on;
        if numel(X) >= 3 && ~isempty(X{1,3})
            scatter(X{1,3}(:,2), X{1,3}(:,1), 25, 'w', 'filled', ...
                    'MarkerEdgeColor','k', 'LineWidth',1);
        end
        title(sprintf('Prediction (corr=%.3f)', mat_corr(X{1,2}, ypred)));
        axis image off;

        nexttile; 
        imagesc(X{1,2}, [Xmin Xmax]);
        title('Ground truth (+sensors)'); colorbar; axis image off; hold off;

        nexttile('West'); 
        imagesc(reshape(X{1,1},[sensorNum,1]), [Xmin Xmax]); 
        title('Input sensors'); axis off;

        drawnow; pause(0.6);
    end
end


%% ---- Standard basis responses (as in original script) ----
% Bias response
biasResp = predict(net, zeros(sensorNum,1,1));
if doDisplay
    figure('Name','Bias response (input=zero)'); imagesc(biasResp); colorbar; axis image;
    title('Model predictions for zero - bias');
end

% Standard basis vectors e_i
if doDisplay
    SB = eye(sensorNum);
    figure('Name','Standard basis responses');
    for i = 1:sensorNum
        v = reshape(SB(:,i), [sensorNum,1,1]);
        ypred = predict(net, v) - biasResp;
        imagesc(ypred); axis image; colorbar;
        title(sprintf('Prediction on standard basis %d (minus bias)', i));
        drawnow; pause(0.6); clf;
    end
end

%% ---- SVD analysis + montages (FC layer) ----
if doDisplay && doSVD
    % SVD of FC weights
    W = net.Layers(2,1).Weights;    % size: 36000 x sensorNum
    [U,S,V] = svd(W);               % U: 36000x36000, S: 36000xsensorNum, V: sensorNumxsensorNum

    % Show weights and singular values
    figure('Name','FC Weights'); imagesc(W); colorbar; title('Fully Connected Weights (W)');
    figure('Name','Singular values'); plot(diag(S),'LineWidth',1.2); grid on; title('Singular values of W');

    
    % Montage of the first sensorNum left singular vectors (U), reshaped to 300x120
    % U(:,i) corresponds to output (36000 = 300*120). Reshape with transpose to [300x120].
    imgs = cell(1, sensorNum);
    for i = 1:sensorNum
        u = reshape(U(:,i), [120,300])';   % -> 300x120
        imgs{i} = u;
    end
    % Build a montage-like figure using tiledlayout (works for matrix images)
    cols = ceil(sqrt(sensorNum));
    rows = ceil(sensorNum/cols);
    figure('Name','SVD U basis (first sensorNum vectors)');
    t = tiledlayout(rows, cols, "Padding","compact","TileSpacing","compact");
    for i = 1:sensorNum
        nexttile; imagesc(imgs{i}); axis image off;
    end
        %% ---- Save U-basis montage as PNG and GIF ----
    % Ask where to save (default: same folder as network file if chosen earlier)
    if exist('savePath','var') && ischar(savePath) && ~isequal(savePath,0)
        outDir = savePath;
    else
        outDir = uigetdir('', 'Select folder to save U-basis montage/GIF');
        if isequal(outDir,0), outDir = pwd; end
    end

    % 1) Save PNG (current figure with the montage)
    try
        pngFile = fullfile(outDir, 'U_basis_montage.png');
        exportgraphics(gcf, pngFile, 'Resolution', 300);
        fprintf('Saved U-basis montage PNG: %s\n', pngFile);
    catch ME
        warning(ME.identifier, 'Failed to save PNG: %s', ME.message);
    end

    % 2) Build an animated GIF sweeping through U basis (one frame per vector)
    try
        gifFile = fullfile(outDir, 'U_basis.gif');
        delay = 0.25;  % seconds between frames
        clim = [];     % hold color limits fixed for consistent contrast

        % Create a hidden figure for consistent frames
        fh = figure('Visible','off');
        for i = 1:numel(imgs)
            imagesc(imgs{i});
            axis image off; colorbar;
            title(sprintf('U(:,%d)', i));
            if isempty(clim), clim = caxis; else, caxis(clim); end
            drawnow;

            frame = getframe(fh);
            [im, map] = rgb2ind(frame2im(frame), 256, 'nodither');
            if i == 1
                imwrite(im, map, gifFile, 'gif', 'LoopCount', Inf, 'DelayTime', delay);
            else
                imwrite(im, map, gifFile, 'gif', 'WriteMode', 'append', 'DelayTime', delay);
            end
        end
        close(fh);
        fprintf('Saved U-basis GIF: %s\n', gifFile);
    catch ME
        warning(ME.identifier, 'Failed to create GIF: %s', ME.message);
    end
end
toc;

%% ----------------------------- Supporting functions -----------------------------
function p = make_read_func(sensorNum, epsilon)
% Returns a ReadFcn that maps a file path -> {sensorVector, fullImage, sensorsUsed}
%  - Reads X from field "X" if present; otherwise first 2D variable.
%  - Reads sensors from field "sensors" or "selectedPixels".
%  - Uses the first "sensorNum" rows of sensors (row,col) 1-based indices.
%  - Adds multiplicative zero-mean Gaussian noise with scale "epsilon".
    p = @read_func;

    function out = read_func(fpath)
        S = load(fpath);
        % Resolve full image X
        if isfield(S,'X')
            Xfull = S.X;
        else
            fn = fieldnames(S);
            Xfull = [];
            for k = 1:numel(fn)
                if ismatrix(S.(fn{k}))
                    Xfull = S.(fn{k}); break;
                end
            end
            if isempty(Xfull)
                error('No 2D matrix found in file: %s', fpath);
            end
        end

        % Resolve sensors
        if isfield(S,'sensors')
            sens = S.sensors;
        elseif isfield(S,'selectedPixels')
            sens = S.selectedPixels;
        else
            error('No sensors/selectedPixels in file: %s', fpath);
        end

        if size(sens,2) < 2 || size(sens,1) < sensorNum
            error('Insufficient sensors in file: %s', fpath);
        end

        sensK = sens(1:sensorNum, 1:2);    % take first K sensors
        linIdx = sub2ind(size(Xfull), sensK(:,1), sensK(:,2));
        v = Xfull(linIdx);

        % multiplicative Gaussian noise
        v = v + epsilon*randn(sensorNum,1).*v;

        out = {reshape(v,[sensorNum,1,1]), Xfull, sensK};
    end
end

function c = mat_corr(A,B)
% Frobenius-cosine similarity after mean-centering
    A = A - mean(A,"all");
    B = B - mean(B,"all");
    c = trace(A'*B) / (norm(A,"fro")*norm(B,"fro") + 1e-12);
end
