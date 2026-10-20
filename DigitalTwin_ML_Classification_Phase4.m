% =========================================================================
% Phase 4 (v3)：Digital-twin 合成資料 + 由訊號量測的品質閉環 + BR/HR 誤差 + 分類
% =========================================================================
clear; clc; close all;

%% 設定
fps = 100; nSamples = 150; nSeeds = 10;
qThresh = 12;                 % 心跳頻帶 峰值/中位數 功率比低於此值 → 觀測窗 10 s 延長到 15 s
addRoadVibration = false;     % true：加入 1–3 Hz 路面振動（落在心跳頻帶內，較困難）
classNames = {'Normal','Stress','Baby(CPD)'};
modes    = {'default','fine'};            % Welch：預設 / 整段視窗 + 細頻率格點
featSets = {'freq','freq+energy'};        % 特徵：只用頻率 / 頻率 + 能量比 + 峰值品質

acc   = nan(nSeeds,3,2,2);                % seed × class × mode × featSet
brOK  = nan(nSeeds,3,2);  hrOK  = nan(nSeeds,3,2);
brMAE = nan(nSeeds,3,2);  hrMAE = nan(nSeeds,3,2);
extRate = nan(nSeeds,2);
Dplot = []; predPlot = [];

%% 主迴圈
for mi = 1:2
  for sd = 1:nSeeds
    rng(sd);
    D = generateDataset(nSamples, fps, modes{mi}, qThresh, addRoadVibration);
    for fi = 1:2
      if fi == 1, cols = [1 2]; else, cols = 1:4; end
      T = array2table(D.X(:,cols));
      T.State = categorical(D.y);
      Mdl  = fitcensemble(T, 'State', 'Method', 'Bag', 'NumLearningCycles', 100);
      pred = string(kfoldPredict(crossval(Mdl, 'KFold', 5)));
      for k = 1:3
        idx = (D.y == classNames{k});
        acc(sd,k,mi,fi) = mean(pred(idx) == classNames{k});
      end
      if mi == 2 && fi == 2 && sd == 1, Dplot = D; predPlot = pred; end
    end
    relBR = abs(D.X(:,1) - D.truthBR) ./ D.truthBR;
    relHR = abs(D.X(:,2) - D.truthHR) ./ D.truthHR;
    for k = 1:3
      idx = (D.y == classNames{k});
      brOK(sd,k,mi)  = mean(relBR(idx) <= 0.05);
      hrOK(sd,k,mi)  = mean(relHR(idx) <= 0.05);
      brMAE(sd,k,mi) = 60*mean(abs(D.X(idx,1) - D.truthBR(idx)));
      hrMAE(sd,k,mi) = 60*mean(abs(D.X(idx,2) - D.truthHR(idx)));
    end
    extRate(sd,mi) = mean(D.ext);
  end
end

%% 輸出結果
fprintf('\n=== 每類準確率 (5-fold CV，%d 個隨機種子的 mean +/- std) ===\n', nSeeds);
for mi = 1:2
  for fi = 1:2
    fprintf('Welch %-7s | 特徵 %-12s :', modes{mi}, featSets{fi});
    for k = 1:3
      a = 100*acc(:,k,mi,fi);
      fprintf('   %s %.1f +/- %.1f%%', classNames{k}, mean(a), std(a));
    end
    fprintf('\n');
  end
end
for mi = 1:2
  fprintf('\n=== BR / HR 估計 (Welch %s)，觀測窗延長比例 %.0f%% ===\n', modes{mi}, 100*mean(extRate(:,mi)));
  for k = 1:3
    fprintf('  %-10s BR MAE %.2f bpm (+/-5%%命中 %.0f%%) | HR MAE %.2f bpm (+/-5%%命中 %.0f%%)\n', ...
      classNames{k}, mean(brMAE(:,k,mi)), 100*mean(brOK(:,k,mi)), ...
      mean(hrMAE(:,k,mi)), 100*mean(hrOK(:,k,mi)));
  end
end

%% 圖 1：特徵空間 + 混淆矩陣 (seed 1，fine Welch，頻率+能量特徵)
figure('Position',[100 100 1000 420]);
subplot(1,2,1);
gscatter(Dplot.X(:,1), Dplot.X(:,2), Dplot.y, 'rgb', 'osd');
xlabel('Extracted Breathing Frequency (Hz)'); ylabel('Extracted Heartbeat Frequency (Hz)');
title('Feature Space (fine Welch)'); grid on;
subplot(1,2,2);
confusionchart(categorical(Dplot.y, classNames), categorical(predPlot, classNames));
title('Confusion Matrix (5-fold CV, seed 1)');

%% 圖 2：四種設定的每類準確率 (mean +/- std)
cfg = [1 1; 1 2; 2 1; 2 2];                 % [mode feat]
M = zeros(3,4); S = zeros(3,4);
for c = 1:4
    a = squeeze(acc(:,:,cfg(c,1),cfg(c,2)));  % nSeeds × 3
    M(:,c) = 100*mean(a,1)';
    S(:,c) = 100*std(a,0,1)';
end

colors = [0.80 0.80 0.78;    % default Welch, freq          淺灰
    0.55 0.55 0.53;    % default Welch, freq+energy   深灰
    0.66 0.83 0.76;    % fine Welch,    freq          淺綠
    0.11 0.62 0.46];   % fine Welch,    freq+energy   綠

fig2 = figure('Position',[100 100 900 450],'Color','w');
b = bar(M, 'BarWidth', 0.8); hold on;
for c = 1:4
    b(c).FaceColor = colors(c,:);
    b(c).EdgeColor = 'none';
    errorbar(b(c).XEndPoints, M(:,c), S(:,c), 'LineStyle','none', ...
        'Color',[0.25 0.25 0.25], 'LineWidth',1, 'CapSize',6);
end
ax = gca; ax.XTickLabel = classNames; ax.GridAlpha = 0.15; ax.Box = 'off'; grid on;
ylabel('Accuracy (%)'); ylim([0 105]);
legend({'default Welch, freq', 'default Welch, freq+energy', ...
    'fine Welch, freq', 'fine Welch, freq+energy'}, ...
    'Location','southoutside', 'NumColumns',2, 'Box','off');
title('Per-class accuracy (mean +/- std over seeds)');
exportgraphics(fig2, 'phase4_accuracy_ablation.png', 'Resolution', 300);
figure('Position',[100 100 520 420]);
gscatter(Dplot.X(:,2), Dplot.X(:,3), Dplot.y, 'rgb', 'osd');
xlabel('Extracted Heartbeat Frequency (Hz)');
ylabel('log10 (HR peak power / BR peak power)');
title('Energy-ratio feature (fine Welch, seed 1)'); grid on;
exportgraphics(gcf, 'phase4_energy_feature.png', 'Resolution', 300);

%% ===================== 區域函式（必須放在檔案最後）=====================
function D = generateDataset(n, fps, mode, qThresh, addRoad)
  lambda = 3e8/60e9;
  X = zeros(n,4); y = strings(n,1); tBR = zeros(n,1); tHR = zeros(n,1); ext = false(n,1);
  %      呼吸中心 抖動  振幅(m)  心跳中心 抖動  振幅(m)
  P = [0.25 0.05 0.0050  1.20 0.10 0.0005;     % Normal
       0.50 0.05 0.0040  1.80 0.15 0.0006;     % Stress
       0.40 0.05 0.0015  2.20 0.20 0.0002];    % Baby(CPD)
  names = ["Normal","Stress","Baby(CPD)"];
  for i = 1:n
    s  = randi(3);
    fr = P(s,1) + P(s,2)*randn;  Ar = P(s,3);
    fh = P(s,4) + P(s,5)*randn;  Ah = P(s,6);
    y(i) = names(s); tBR(i) = fr; tHR(i) = fh;

    % 領域隨機化：雜訊、車晃幅度、車晃頻率、各成分相位
    noiseStd = 0.0005 + 0.001*rand;          % 0.5–1.5 mm
    swayAmp  = 0.005  + 0.015*rand;          % 5–20 mm
    swayFreq = 0.05   + 0.07*rand;           % 0.05–0.12 Hz
    pr = 2*pi*rand(1,3);

    t = (0:15*fps-1)/fps;                    % 一律產生 15 s，閉環決定使用多長
    d = Ar*sin(2*pi*fr*t + pr(1)) + Ah*sin(2*pi*fh*t + pr(2)) ...
        + swayAmp*sin(2*pi*swayFreq*t + pr(3)) + noiseStd*randn(size(t));
    if addRoad
      d = d + (0.0002 + 0.0006*rand)*sin(2*pi*(1 + 2*rand)*t + 2*pi*rand);
    end
    phi = 4*pi*d/lambda;

    % 閉環：由訊號量測品質（前 10 s 心跳頻帶峰值/中位數）
    h10 = bpf(phi(1:10*fps), 0.8, 2.5, fps);
    [~, ~, q10] = spectralPeak(h10, fps, 'fine', [0.8 2.5]);
    L = 10*fps;
    if q10 < qThresh, L = 15*fps; ext(i) = true; end

    b = bpf(phi(1:L), 0.15, 0.7, fps);
    h = bpf(phi(1:L), 0.8,  2.5, fps);
    [fBR, pBR, ~]  = spectralPeak(b, fps, mode, [0.15 0.7]);
    [fHR, pHR, qH] = spectralPeak(h, fps, mode, [0.8 2.5]);
    X(i,:) = [fBR, fHR, log10(pHR/pBR), qH];
  end
  D = struct('X', X, 'y', y, 'truthBR', tBR, 'truthHR', tHR, 'ext', ext);
end

function y = bpf(x, lo, hi, fps)
  [z,p,k] = butter(2, [lo hi]/(fps/2), 'bandpass');
  [sos,g] = zp2sos(z,p,k);
  y = filtfilt(sos, g, x);
end

function [f0, pk, q] = spectralPeak(x, fps, mode, band)
  if strcmp(mode,'default')
    [p,f] = pwelch(x, [], [], [], fps);
  else
    [p,f] = pwelch(x, hamming(numel(x)), 0, 8192, fps);
  end
  m = (f >= band(1)) & (f <= band(2));
  pm = p(m); fm = f(m);
  [pk, i] = max(pm);
  f0 = fm(i);
  q  = pk / median(pm);
end


