% =========================================================================
% Phase 5 (v3)：多天線空間濾波示意（物理一致的相位調變模型）
% 假設：兩位乘員在同一距離格、不同角度；4-RX、λ/2 間距；座位角度有估計誤差
% =========================================================================
clear; clc; close all;

%% 參數
fps = 100; duration = 10; N = fps*duration; t = (0:N-1)/fps;
lambda = 3e8/60e9; nRx = 4; d = lambda/2;
ampAdult = 1.5; ampBaby = 1.0;       % 回波振幅（成人較強）
sigma    = 1.0;                      % 每根天線複數雜訊標準差（嬰兒回波振幅 = 1.0）
angBaby = 15; angAdult = -20;
steerErr = 2;                        % 座位角度估計誤差（度）
nTrials  = 30; trueBR = 0.40; trueHR = 2.20;
steer = @(deg) exp(-1i*2*pi*d/lambda*(0:nRx-1)'*sind(deg));

%% 乘員位移（車晃為共同項）
xAdult = 0.005*sin(2*pi*0.25*t) + 0.0005*sin(2*pi*1.20*t);
xBaby  = 0.0015*sin(2*pi*0.40*t) + 0.0002*sin(2*pi*2.20*t);
sway   = 0.008*sin(2*pi*0.1*t);
phiAdult     = 4*pi*(xAdult + sway)/lambda;
phiBaby      = 4*pi*(xBaby  + sway)/lambda;
phiBabyVital = 4*pi*xBaby/lambda;                           % 真值（不含車晃）
truth = bpf(phiBabyVital - mean(phiBabyVital), 0.15, 2.5, fps);

%% 波束權重（只用「估計」角度）
aBabyEst  = steer(angBaby  + steerErr);
aAdultEst = steer(angAdult - steerErr);
wConv = aBabyEst / nRx;                         % 傳統 delay-and-sum
A = [aBabyEst, aAdultEst];
wNull = A / (A'*A) * [1; 0];                    % 指向嬰兒、對成人形成零點

%% Monte Carlo
rng(1);
methods = {'single','conv','null'};
rmse = zeros(nTrials,3); estBR = zeros(nTrials,3); estHR = zeros(nTrials,3);
estPlot = cell(1,3);
for tr = 1:nTrials
  noise = sigma*(randn(nRx,N) + 1i*randn(nRx,N))/sqrt(2);
  rx = ampBaby*steer(angBaby)*exp(1i*phiBaby) ...
     + ampAdult*steer(angAdult)*exp(1i*phiAdult) + noise;
  ys = {rx(1,:), wConv'*rx, wNull'*rx};
  for m = 1:3
    est = vitalPhase(ys{m}, fps);
    idx = fps+1 : N-fps;
    rmse(tr,m)  = sqrt(mean((est(idx) - truth(idx)).^2));
    estBR(tr,m) = peakFreq(est, fps, [0.15 0.7]);
    estHR(tr,m) = peakFreq(est, fps, [0.8 2.6]);
    if tr == 1, estPlot{m} = est; end
  end
end

fprintf('\nMethod   | phase RMSE (rad) | BR within +/-5%% | HR within +/-5%% | median HR peak (Hz)\n');
for m = 1:3
  fprintf('%-8s | %8.2f         | %8.0f%%      | %8.0f%%      | %.2f\n', methods{m}, mean(rmse(:,m)), ...
    100*mean(abs(estBR(:,m)-trueBR)/trueBR <= 0.05), ...
    100*mean(abs(estHR(:,m)-trueHR)/trueHR <= 0.05), median(estHR(:,m)));
end

%% 頻譜（√PSD，正規化）
spec = cell(1,3);
for m = 1:3
  [p,f] = pwelch(estPlot{m}, hamming(600), 540, 8192, fps);
  spec{m} = sqrt(p)/max(sqrt(p));
end

%% 繪圖
fig = figure('Position',[50 50 1280 640],'Color','w');
tiledlayout(2,2,'TileSpacing','loose','Padding','loose');

nexttile(1);
plot(t, estPlot{1}, 'Color',[0.55 0.55 0.55],'LineWidth',1.1); hold on;
plot(t, truth, 'r','LineWidth',1.6);
title('1A. Single antenna','FontSize',11,'FontWeight','bold');
ylabel('Phase (rad)'); xlim([0 10]); ylim([-15 15]); yticks(-10:5:10); grid on;
legend('Single-antenna phase','Baby ground truth','Location','northeast','FontSize',9);

nexttile(3);
plot(t, estPlot{2}, 'b','LineWidth',1.5); hold on;
plot(t, truth, 'r','LineWidth',1.6);
title('1B. Beamformed toward +15° seat','FontSize',11,'FontWeight','bold');
xlabel('Time (s)'); ylabel('Phase (rad)'); xlim([0 10]); ylim([-15 15]); yticks(-10:5:10); grid on;
legend('Beamformed phase','Baby ground truth','Location','northeast','FontSize',9);

nexttile(2,[2 1]);
plot(f, spec{1}, '--','Color',[0.55 0.55 0.55],'LineWidth',1.4); hold on;
plot(f, spec{2}, 'b','LineWidth',2);
plot(f, spec{3}, '-','Color',[0 0.6 0],'LineWidth',1.4);
plot([0.25 0.25],[0 1.1],'k:','LineWidth',1.3,'HandleVisibility','off');
plot([0.40 0.40],[0 1.1],'r--','LineWidth',1.5,'HandleVisibility','off');
plot([2.20 2.20],[0 0.6],'m--','LineWidth',1.5,'HandleVisibility','off');
xlim([0 3]); ylim([0 1.4]);
text(0.25,1.30,'Adult BR 0.25 Hz','HorizontalAlignment','center','FontSize',9,'BackgroundColor','w','Margin',1);
text(0.43,1.18,'Baby BR 0.40 Hz','HorizontalAlignment','left','Color','r','FontSize',9,'BackgroundColor','w','Margin',1);
text(2.23,0.66,'Baby HR 2.2 Hz','HorizontalAlignment','left','Color','m','FontSize',9,'BackgroundColor','w','Margin',1);
title('2. Amplitude spectrum','FontSize',11,'FontWeight','bold');
xlabel('Frequency (Hz)   (vertical lines = ground-truth frequencies)');
ylabel('Normalized amplitude (sqrt PSD)');
legend('Single antenna','Beamformed (conventional)','Beamformed (null toward adult)', ...
       'Location','northeast','FontSize',9);
grid on;
exportgraphics(fig,'phase5_v3.png','Resolution',300);

%% ===================== 區域函式 =====================
function out = vitalPhase(y, fps)
  ph  = unwrap(angle(y));
  ph  = ph - mean(ph);
  out = bpf(ph, 0.15, 2.5, fps);
end

function y = bpf(x, lo, hi, fps)
  [z,p,k] = butter(4, [lo hi]/(fps/2), 'bandpass');
  [sos,g] = zp2sos(z,p,k);
  y = filtfilt(sos, g, x);
end

function f0 = peakFreq(x, fps, band)
  [p,f] = pwelch(x, hamming(600), 540, 8192, fps);
  m = (f >= band(1)) & (f <= band(2));
  fm = f(m); [~,i] = max(p(m)); f0 = fm(i);
end
