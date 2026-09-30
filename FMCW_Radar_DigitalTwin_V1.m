% =========================================================================
% 專題名稱：車內乘客呼吸心跳偵測與數位孿生系統 (Phase 1: 靜態目標雷達測距)
% =========================================================================

% -------------------------------------------------------------------------
% 1. 定義雷達硬體與 FMCW 訊號參數
% -------------------------------------------------------------------------
fc = 60e9;             % 操作頻率 60 GHz (毫米波雷達)
bw = 4e9;              % 掃頻帶寬 4 GHz (決定距離解析度)
sweepTime = 1e-3;      % 每次掃描時間 1 毫秒
fs = 2 * bw;           % 取樣頻率 8 GHz (依據奈奎斯特理論)
c = 3e8;               % 光速 (m/s)
slope = bw / sweepTime;% 掃頻斜率 S = B/T (Hz/s)

% 建立 FMCW 波形發射器物件
waveform = phased.FMCWWaveform('SampleRate', fs, ...
    'SweepTime', sweepTime, ...
    'SweepBandwidth', bw);

% 發射一個脈衝的電磁波 (Chirp)
txSig = waveform();

% -------------------------------------------------------------------------
% 2. 建立空間通道與數位孿生乘客 (目標)
% -------------------------------------------------------------------------
% 建立空間傳遞通道 (考慮雙向傳播延遲與衰減)
channel = phased.FreeSpace('OperatingFrequency', fc, ...
    'TwoWayPropagation', true, ...
    'SampleRate', fs);

% 建立雷達目標 (設定雷達截面積為 1 平方公尺，模擬人體軀幹)
target = phased.RadarTarget('MeanRCS', 1, 'OperatingFrequency', fc);

% 設定 3D 空間座標
radar_pos = [0; 0; 0];         % 雷達架設於原點 (0m)
target_pos = [0.8; 0; 0];      % 乘客坐在 X 軸正前方 0.8 公尺處
radar_vel = [0; 0; 0];         % 雷達靜止
target_vel = [0; 0; 0];        % 目標靜止

% 模擬電磁波發射、穿過空間、打到乘客並反射回來
propSig = channel(txSig, radar_pos, target_pos, radar_vel, target_vel);
rxSig = target(propSig);       % rxSig 為雷達天線收到的微弱回波

% -------------------------------------------------------------------------
% 3. 訊號處理 (DSP)：混頻 (Dechirp) 與 快速傅立葉變換 (Range FFT)
% -------------------------------------------------------------------------
% 混頻器 (Mixer)：將回波與發射波相乘，萃取出中頻拍頻訊號 (Beat Signal)
beatSig = dechirp(rxSig, txSig);

% 執行 FFT 將時域拍頻訊號轉換為頻譜
L = length(beatSig);      
Y = fft(beatSig);         
P2 = abs(Y / L);
P1 = P2(1:floor(L/2)+1);
P1(2:end-1) = 2 * P1(2:end-1);

% 將頻率軸 (f) 轉換為距離軸 (range_grid)
f = fs * (0:floor(L/2)) / L; 
range_grid = (f * c) / (2 * slope); % FMCW 測距核心公式

% -------------------------------------------------------------------------
% 4. 繪製距離頻譜圖 (Range Profile)
% -------------------------------------------------------------------------
figure;
plot(range_grid, mag2db(P1), 'LineWidth', 1.5);
xlim([0 2]);            % 專注觀察 0 到 2 公尺的車內空間
ylim([-150 -50]);       % 調整訊號強度的顯示範圍
xlabel('Distance (meters)');
ylabel('Echo Strength (dB)');
title('Radar Range FFT: In-Cabin Passenger Detection');
grid on;

% 自動抓取並標示訊號最強的峰值 (Peak)，驗證測距結果
[max_val, max_idx] = max(P1);
detected_range = range_grid(max_idx);
hold on;
plot(detected_range, mag2db(max_val), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
text(detected_range+0.05, mag2db(max_val), sprintf('Detected: %.3f m', detected_range), ...
    'Color', 'r', 'FontWeight', 'bold');