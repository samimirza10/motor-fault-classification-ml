%% ========================================================================
% Motor Fault Classification — 7 Fast Models with Enhanced Visualizations
% 3-Phase Motor Current Analysis (Time & Frequency Domain)
% ========================================================================

clear; clc; close all;

%% ================= USER SETTINGS =================
baseDir = 'Motorfaultdataset';
folders = { 'Healthy', 'BRB_100', 'BRB_300', 'BFI_100', 'BFI_200', 'BFI_300', 'BFO_100', 'BFO_200', 'BFO_300' };
labels  = { 'Healthy', 'BRB100', 'BRB300', 'BFI100', 'BFI200', 'BFI300', 'BFO100', 'BFO200', 'BFO300' };

rng(42);
testRatio = 0.15;
valRatio  = 0.15;

% Sampling parameters for 3-phase motor
samplingRate = 10000; % Hz - INCREASED for better FFT resolution
phaseNames = {'Phase A', 'Phase B', 'Phase C'};

% Bearing fault frequencies (typical for motor at 50 Hz)
% BPFO (Ball Pass Frequency Outer): ~3.5x line frequency = 175 Hz
% BPFI (Ball Pass Frequency Inner): ~5.4x line frequency = 270 Hz
% BSF (Ball Spin Frequency): ~2.3x line frequency = 115 Hz
% FTF (Fundamental Train Frequency): ~0.4x line frequency = 20 Hz
motorFreq = 50; % Hz
BPFO = 3.5 * motorFreq; % ~175 Hz
BPFI = 5.4 * motorFreq; % ~270 Hz
BSF = 2.3 * motorFreq;  % ~115 Hz
FTF = 0.4 * motorFreq;  % ~20 Hz

%% ================= LOAD DATA =====================
X = [];
Y = [];
allRawData = {}; % Store raw data samples for visualization

fprintf("Loading dataset...\n");

% Load all data
for i = 1:length(folders)
    folderPath = fullfile(baseDir, folders{i});
    csvFiles = dir(fullfile(folderPath, '*.csv'));
    
    for j = 1:length(csvFiles)
        csvPath = fullfile(folderPath, csvFiles(j).name);
        fprintf("  Loading: %s (%s)\n", csvFiles(j).name, folders{i});
        
        data = readmatrix(csvPath);
        
        % Assume 3 columns for 3-phase motor (adjust if needed)
        if size(data, 2) >= 3
            numericData = data(:, 1:3); % Phase A, B, C
        else
            numericData = data;
        end
        
        % Store FIRST file from each class for visualization
        if j == 1
            allRawData{end+1} = struct('data', numericData, ...
                                       'label', labels{i}, ...
                                       'folder', folders{i});
        end
        
        % Each row is a sample for classification
        X = [X; numericData];
        Y = [Y; repmat(labels(i), size(numericData,1), 1)];
    end
end

Y = categorical(Y);
fprintf("Data loaded: %d samples, %d features, %d classes\n", size(X,1), size(X,2), numel(categories(Y)));

%% ================= TIME & FREQUENCY DOMAIN VISUALIZATION =================
fprintf("\n=== Creating Time and Frequency Domain Plots ===\n");

% Find healthy and first defect data
healthyData = [];
defectData = [];
defectLabel = '';

for i = 1:length(allRawData)
    if strcmp(allRawData{i}.folder, 'Healthy')
        healthyData = allRawData{i}.data;
    elseif isempty(defectData)
        defectData = allRawData{i}.data;
        defectLabel = allRawData{i}.label;
    end
end

% ONLY plot if data exists and has reasonable size
if ~isempty(healthyData) && size(healthyData, 1) > 10
    N_healthy = size(healthyData, 1);
    timeVector_healthy = (0:N_healthy-1) / samplingRate;
    
    % Time Domain - Healthy
    figure('Position', [50, 50, 1400, 800]);
    sgtitle('Time Domain - Healthy Motor', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        subplot(3,1,phase);
        plot(timeVector_healthy, healthyData(:, phase), 'b', 'LineWidth', 1.2);
        grid on;
        title(phaseNames{phase});
        xlabel('Time (s)');
        ylabel('Current (A)');
        xlim([0 max(timeVector_healthy)]);
    end
end

if ~isempty(defectData) && size(defectData, 1) > 10
    N_defect = size(defectData, 1);
    timeVector_defect = (0:N_defect-1) / samplingRate;
    
    % Time Domain - Defect
    figure('Position', [100, 50, 1400, 800]);
    sgtitle(['Time Domain - ' defectLabel], 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        subplot(3,1,phase);
        plot(timeVector_defect, defectData(:, phase), 'r', 'LineWidth', 1.2);
        grid on;
        title(phaseNames{phase});
        xlabel('Time (s)');
        ylabel('Current (A)');
        xlim([0 max(timeVector_defect)]);
    end
end

% Comparison Plot - Healthy vs Defect
if ~isempty(healthyData) && ~isempty(defectData)
    % Take minimum length for comparison
    minLen = min(size(healthyData,1), size(defectData,1));
    timeVector_comp = (0:minLen-1) / samplingRate;
    
    figure('Position', [150, 50, 1400, 900]);
    sgtitle('Time Domain Comparison: Healthy vs Defect', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        subplot(3,1,phase);
        hold on;
        plot(timeVector_comp, healthyData(1:minLen, phase), 'b', 'LineWidth', 1.5, 'DisplayName', 'Healthy');
        plot(timeVector_comp, defectData(1:minLen, phase), 'r', 'LineWidth', 1.5, 'DisplayName', defectLabel);
        grid on;
        legend('Location', 'best');
        title(phaseNames{phase});
        xlabel('Time (s)');
        ylabel('Current (A)');
        xlim([0 max(timeVector_comp)]);
        hold off;
    end
end

% FFT Analysis with proper normalization
if ~isempty(healthyData) && size(healthyData,1) > 10
    figure('Position', [200, 50, 1400, 900]);
    sgtitle('Frequency Domain Analysis - Supply Frequency Range (40-70 Hz)', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        % Healthy FFT
        signal_h = healthyData(:, phase);
        N_h = length(signal_h);
        
        % Remove DC component and apply window
        signal_h = signal_h - mean(signal_h);
        window_h = hamming(N_h);
        signal_h = signal_h .* window_h;
        
        % Compute FFT
        fft_h = fft(signal_h);
        P2_h = abs(fft_h/N_h);
        P1_h = P2_h(1:floor(N_h/2)+1);
        P1_h(2:end-1) = 2*P1_h(2:end-1);
        freq_h = samplingRate*(0:floor(N_h/2))/N_h;
        
        subplot(3,2,2*phase-1);
        
        % Focus on 40-70 Hz range for slip frequency analysis
        idx_h = freq_h >= 40 & freq_h <= 70;
        plot(freq_h(idx_h), P1_h(idx_h), 'b', 'LineWidth', 1.5);
        grid on;
        title(['Healthy - ' phaseNames{phase}]);
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([40, 70]);
        if max(P1_h(idx_h)) > 0
            ylim([0, max(P1_h(idx_h))*1.1]);
        end
        
        % Mark motor frequency
        xline(motorFreq, 'k--', 'LineWidth', 1.5, 'Alpha', 0.5);
        
        % Defect FFT
        if ~isempty(defectData) && size(defectData,1) > 10
            signal_d = defectData(:, phase);
            N_d = length(signal_d);
            
            % Remove DC component and apply window
            signal_d = signal_d - mean(signal_d);
            window_d = hamming(N_d);
            signal_d = signal_d .* window_d;
            
            % Compute FFT
            fft_d = fft(signal_d);
            P2_d = abs(fft_d/N_d);
            P1_d = P2_d(1:floor(N_d/2)+1);
            P1_d(2:end-1) = 2*P1_d(2:end-1);
            freq_d = samplingRate*(0:floor(N_d/2))/N_d;
            
            subplot(3,2,2*phase);
            
            % Focus on 40-70 Hz range for slip frequency analysis
            idx_d = freq_d >= 40 & freq_d <= 70;
            plot(freq_d(idx_d), P1_d(idx_d), 'r', 'LineWidth', 1.5);
            grid on;
            title([defectLabel ' - ' phaseNames{phase}]);
            xlabel('Frequency (Hz)');
            ylabel('Magnitude');
            xlim([40, 70]);
            if max(P1_d(idx_d)) > 0
                ylim([0, max(P1_d(idx_d))*1.1]);
            end
            
            % Mark motor frequency
            xline(motorFreq, 'k--', 'LineWidth', 1.5, 'Alpha', 0.5);
        end
    end
end

% FFT Overlay Comparison
if ~isempty(healthyData) && ~isempty(defectData)
    figure('Position', [250, 50, 1400, 500]);
    sgtitle('FFT Comparison: Healthy vs Defect - Supply Frequency Range', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        % Healthy FFT
        signal_h = healthyData(:, phase);
        signal_h = signal_h - mean(signal_h);
        N_h = length(signal_h);
        window_h = hamming(N_h);
        signal_h = signal_h .* window_h;
        
        fft_h = fft(signal_h);
        P2_h = abs(fft_h/N_h);
        P1_h = P2_h(1:floor(N_h/2)+1);
        P1_h(2:end-1) = 2*P1_h(2:end-1);
        freq_h = samplingRate*(0:floor(N_h/2))/N_h;
        
        % Defect FFT
        signal_d = defectData(:, phase);
        signal_d = signal_d - mean(signal_d);
        N_d = length(signal_d);
        window_d = hamming(N_d);
        signal_d = signal_d .* window_d;
        
        fft_d = fft(signal_d);
        P2_d = abs(fft_d/N_d);
        P1_d = P2_d(1:floor(N_d/2)+1);
        P1_d(2:end-1) = 2*P1_d(2:end-1);
        freq_d = samplingRate*(0:floor(N_d/2))/N_d;
        
        subplot(1,3,phase);
        hold on;
        
        % Focus on 40-70 Hz range for slip frequency sidebands
        idx_h = freq_h >= 40 & freq_h <= 70;
        idx_d = freq_d >= 40 & freq_d <= 70;
        
        plot(freq_h(idx_h), P1_h(idx_h), 'b', 'LineWidth', 2, 'DisplayName', 'Healthy');
        plot(freq_d(idx_d), P1_d(idx_d), 'r', 'LineWidth', 2, 'DisplayName', defectLabel);
        grid on;
        legend('Location', 'best');
        title(phaseNames{phase});
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([40, 70]);
        
        % Mark motor frequency
        xline(motorFreq, 'k--', 'LineWidth', 1.5, 'Alpha', 0.5);
        text(motorFreq, max(ylim)*0.95, sprintf('f_s=%dHz', motorFreq), ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'BackgroundColor', 'white');
        
        hold off;
    end
end

%% ================= BEARING FAULT FREQUENCY ANALYSIS =================
fprintf("\n=== Bearing Fault Frequency Analysis (100-400 Hz) ===\n");

if ~isempty(healthyData) && ~isempty(defectData)
    figure('Position', [300, 50, 1600, 900]);
    sgtitle('Bearing Fault Frequency Analysis - High Frequency Range', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        % Healthy FFT
        signal_h = healthyData(:, phase);
        signal_h = signal_h - mean(signal_h);
        N_h = length(signal_h);
        window_h = hamming(N_h);
        signal_h = signal_h .* window_h;
        
        fft_h = fft(signal_h);
        P2_h = abs(fft_h/N_h);
        P1_h = P2_h(1:floor(N_h/2)+1);
        P1_h(2:end-1) = 2*P1_h(2:end-1);
        freq_h = samplingRate*(0:floor(N_h/2))/N_h;
        
        % Defect FFT
        signal_d = defectData(:, phase);
        signal_d = signal_d - mean(signal_d);
        N_d = length(signal_d);
        window_d = hamming(N_d);
        signal_d = signal_d .* window_d;
        
        fft_d = fft(signal_d);
        P2_d = abs(fft_d/N_d);
        P1_d = P2_d(1:floor(N_d/2)+1);
        P1_d(2:end-1) = 2*P1_d(2:end-1);
        freq_d = samplingRate*(0:floor(N_d/2))/N_d;
        
        % Plot bearing fault frequency range (100-400 Hz)
        subplot(3,2,2*phase-1);
        idx_h = freq_h >= 100 & freq_h <= 400;
        plot(freq_h(idx_h), P1_h(idx_h), 'b', 'LineWidth', 1.5);
        grid on;
        title(['Healthy - ' phaseNames{phase}]);
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([100, 400]);
        
        % Mark bearing fault frequencies
        hold on;
        xline(BSF, 'g--', 'LineWidth', 1.2, 'Alpha', 0.4);
        xline(BPFO, 'm--', 'LineWidth', 1.2, 'Alpha', 0.4);
        xline(BPFI, 'r--', 'LineWidth', 1.2, 'Alpha', 0.4);
        
        % Add labels
        ymax = max(ylim);
        text(BSF, ymax*0.9, sprintf('BSF\n%.0fHz', BSF), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'g');
        text(BPFO, ymax*0.8, sprintf('BPFO\n%.0fHz', BPFO), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'm');
        text(BPFI, ymax*0.7, sprintf('BPFI\n%.0fHz', BPFI), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'r');
        hold off;
        
        subplot(3,2,2*phase);
        idx_d = freq_d >= 100 & freq_d <= 400;
        plot(freq_d(idx_d), P1_d(idx_d), 'r', 'LineWidth', 1.5);
        grid on;
        title([defectLabel ' - ' phaseNames{phase}]);
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([100, 400]);
        
        % Mark bearing fault frequencies
        hold on;
        xline(BSF, 'g--', 'LineWidth', 1.2, 'Alpha', 0.4);
        xline(BPFO, 'm--', 'LineWidth', 1.2, 'Alpha', 0.4);
        xline(BPFI, 'r--', 'LineWidth', 1.2, 'Alpha', 0.4);
        
        % Add labels
        ymax = max(ylim);
        text(BSF, ymax*0.9, sprintf('BSF\n%.0fHz', BSF), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'g');
        text(BPFO, ymax*0.8, sprintf('BPFO\n%.0fHz', BPFO), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'm');
        text(BPFI, ymax*0.7, sprintf('BPFI\n%.0fHz', BPFI), 'FontSize', 7, 'HorizontalAlignment', 'center', 'Color', 'r');
        hold off;
    end
end

%% ================= BEARING FAULT OVERLAY COMPARISON =================
if ~isempty(healthyData) && ~isempty(defectData)
    figure('Position', [350, 50, 1600, 500]);
    sgtitle('Bearing Fault Comparison - Healthy vs Defect (100-400 Hz)', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        % Healthy FFT
        signal_h = healthyData(:, phase);
        signal_h = signal_h - mean(signal_h);
        N_h = length(signal_h);
        window_h = hamming(N_h);
        signal_h = signal_h .* window_h;
        
        fft_h = fft(signal_h);
        P2_h = abs(fft_h/N_h);
        P1_h = P2_h(1:floor(N_h/2)+1);
        P1_h(2:end-1) = 2*P1_h(2:end-1);
        freq_h = samplingRate*(0:floor(N_h/2))/N_h;
        
        % Defect FFT
        signal_d = defectData(:, phase);
        signal_d = signal_d - mean(signal_d);
        N_d = length(signal_d);
        window_d = hamming(N_d);
        signal_d = signal_d .* window_d;
        
        fft_d = fft(signal_d);
        P2_d = abs(fft_d/N_d);
        P1_d = P2_d(1:floor(N_d/2)+1);
        P1_d(2:end-1) = 2*P1_d(2:end-1);
        freq_d = samplingRate*(0:floor(N_d/2))/N_d;
        
        subplot(1,3,phase);
        hold on;
        
        % Focus on bearing fault frequency range
        idx_h = freq_h >= 100 & freq_h <= 400;
        idx_d = freq_d >= 100 & freq_d <= 400;
        
        plot(freq_h(idx_h), P1_h(idx_h), 'b', 'LineWidth', 2, 'DisplayName', 'Healthy');
        plot(freq_d(idx_d), P1_d(idx_d), 'r', 'LineWidth', 2, 'DisplayName', defectLabel);
        
        % Mark bearing fault frequencies
        xline(BSF, 'g--', 'LineWidth', 1.5, 'Alpha', 0.5, 'DisplayName', sprintf('BSF (%.0fHz)', BSF));
        xline(BPFO, 'm--', 'LineWidth', 1.5, 'Alpha', 0.5, 'DisplayName', sprintf('BPFO (%.0fHz)', BPFO));
        xline(BPFI, 'r--', 'LineWidth', 1.5, 'Alpha', 0.5, 'DisplayName', sprintf('BPFI (%.0fHz)', BPFI));
        
        grid on;
        legend('Location', 'northeast', 'FontSize', 8);
        title(phaseNames{phase});
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([100, 400]);
        
        hold off;
    end
end

%% ================= FULL SPECTRUM COMPARISON =================
if ~isempty(healthyData) && ~isempty(defectData)
    figure('Position', [400, 50, 1600, 500]);
    sgtitle('Full Spectrum Comparison (0-500 Hz)', 'FontSize', 14, 'FontWeight', 'bold');
    
    for phase = 1:3
        % Healthy FFT
        signal_h = healthyData(:, phase);
        signal_h = signal_h - mean(signal_h);
        N_h = length(signal_h);
        window_h = hamming(N_h);
        signal_h = signal_h .* window_h;
        
        fft_h = fft(signal_h);
        P2_h = abs(fft_h/N_h);
        P1_h = P2_h(1:floor(N_h/2)+1);
        P1_h(2:end-1) = 2*P1_h(2:end-1);
        freq_h = samplingRate*(0:floor(N_h/2))/N_h;
        
        % Defect FFT
        signal_d = defectData(:, phase);
        signal_d = signal_d - mean(signal_d);
        N_d = length(signal_d);
        window_d = hamming(N_d);
        signal_d = signal_d .* window_d;
        
        fft_d = fft(signal_d);
        P2_d = abs(fft_d/N_d);
        P1_d = P2_d(1:floor(N_d/2)+1);
        P1_d(2:end-1) = 2*P1_d(2:end-1);
        freq_d = samplingRate*(0:floor(N_d/2))/N_d;
        
        subplot(1,3,phase);
        hold on;
        
        % Full spectrum view
        idx_h = freq_h >= 0 & freq_h <= 500;
        idx_d = freq_d >= 0 & freq_d <= 500;
        
        plot(freq_h(idx_h), P1_h(idx_h), 'b', 'LineWidth', 1.5, 'DisplayName', 'Healthy');
        plot(freq_d(idx_d), P1_d(idx_d), 'r', 'LineWidth', 1.5, 'DisplayName', defectLabel);
        
        % Mark key frequencies
        xline(motorFreq, 'k--', 'LineWidth', 1.2, 'Alpha', 0.4, 'DisplayName', sprintf('Motor (%.0fHz)', motorFreq));
        xline(BPFI, 'r--', 'LineWidth', 1.2, 'Alpha', 0.4, 'DisplayName', sprintf('BPFI (%.0fHz)', BPFI));
        
        grid on;
        legend('Location', 'northeast', 'FontSize', 7);
        title(phaseNames{phase});
        xlabel('Frequency (Hz)');
        ylabel('Magnitude');
        xlim([0, 500]);
        
        hold off;
    end
end
%% ==================================================

%% ================= FEATURE EXTRACTION FROM FFT ==================
fprintf("\n=== Extracting Frequency-Domain Features ===\n");

% Extract frequency-domain features for classification
X_freq = [];
Y_freq = [];

for i = 1:length(allRawData)
    data = allRawData{i}.data;
    label = allRawData{i}.label;
    
    % Process each phase
    features = [];
    for phase = 1:3
        signal = data(:, phase);
        signal = signal - mean(signal);
        N = length(signal);
        window = hamming(N);
        signal = signal .* window;
        
        % Compute FFT
        fft_sig = fft(signal);
        P2 = abs(fft_sig/N);
        P1 = P2(1:floor(N/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        freq = samplingRate*(0:floor(N/2))/N;
        
        % Extract features in fault-relevant frequency range (40-70 Hz)
        idx = freq >= 40 & freq <= 70;
        
        % Features for fault detection:
        % 1. Peak magnitude in range
        features(end+1) = max(P1(idx));
        
        % 2. Mean magnitude in range
        features(end+1) = mean(P1(idx));
        
        % 3. Magnitude at supply frequency (50 Hz)
        [~, f50_idx] = min(abs(freq - 50));
        features(end+1) = P1(f50_idx);
        
        % 4. Sideband asymmetry (f_s ± f_slip)
        % Left sideband (45-49 Hz)
        idx_left = freq >= 45 & freq < 50;
        left_power = sum(P1(idx_left));
        
        % Right sideband (51-55 Hz)
        idx_right = freq > 50 & freq <= 55;
        right_power = sum(P1(idx_right));
        
        features(end+1) = abs(left_power - right_power); % Asymmetry indicator
        features(end+1) = left_power + right_power; % Total sideband power
        
        % 5. Frequency of maximum peak
        [~, max_idx] = max(P1(idx));
        freq_subset = freq(idx);
        features(end+1) = freq_subset(max_idx);
        
        % ===== BEARING FAULT FEATURES (100-400 Hz) =====
        idx_bearing = freq >= 100 & freq <= 400;
        
        % 6. Total power in bearing fault range
        features(end+1) = sum(P1(idx_bearing));
        
        % 7. Peak magnitude in bearing range
        features(end+1) = max(P1(idx_bearing));
        
        % 8. Power near BPFI (Ball Pass Frequency Inner) - 270 Hz ± 10 Hz
        idx_bpfi = freq >= (BPFI-10) & freq <= (BPFI+10);
        features(end+1) = sum(P1(idx_bpfi));
        
        % 9. Power near BPFO (Ball Pass Frequency Outer) - 175 Hz ± 10 Hz
        idx_bpfo = freq >= (BPFO-10) & freq <= (BPFO+10);
        features(end+1) = sum(P1(idx_bpfo));
        
        % 10. Power near BSF (Ball Spin Frequency) - 115 Hz ± 10 Hz
        idx_bsf = freq >= (BSF-10) & freq <= (BSF+10);
        features(end+1) = sum(P1(idx_bsf));
        
        % 11. Ratio of bearing fault power to motor frequency power
        idx_motor = freq >= (motorFreq-5) & freq <= (motorFreq+5);
        motor_power = sum(P1(idx_motor));
        if motor_power > 0
            features(end+1) = sum(P1(idx_bearing)) / motor_power;
        else
            features(end+1) = 0;
        end
        
        % 12. Standard deviation in bearing range (roughness indicator)
        features(end+1) = std(P1(idx_bearing));
        
        % 13. Kurtosis in bearing range (impulsiveness indicator)
        features(end+1) = kurtosis(P1(idx_bearing));
    end
    
    X_freq = [X_freq; features];
    Y_freq = [Y_freq; string(label)];
end

Y_freq = categorical(Y_freq);

fprintf("Frequency features extracted: %d samples, %d features\n", size(X_freq,1), size(X_freq,2));

% Normalize frequency features
X_freq = zscore(X_freq);
%% ==================================================

%% ============= TRAIN MODELS ON FREQUENCY FEATURES =====
fprintf("\n=== Training Models on Frequency-Domain Features ===\n");

% Split data
cv_freq = cvpartition(Y_freq, "HoldOut", 0.2);
Xtrain_freq = X_freq(cv_freq.training, :);
Ytrain_freq = Y_freq(cv_freq.training);
Xtest_freq = X_freq(cv_freq.test, :);
Ytest_freq = Y_freq(cv_freq.test);

fprintf("Frequency-based splits: Train=%d  Test=%d\n", size(Xtrain_freq,1), size(Xtest_freq,1));

% Train best models on frequency features
freq_models = {};
freq_names = {}; % CHANGED TO CELL ARRAY

fprintf("\n[1/3] Training Random Forest on Freq Features...\n");
try
    freq_models{end+1} = fitcensemble(Xtrain_freq, Ytrain_freq, "Method","Bag", "NumLearningCycles", 50);
    freq_names{end+1} = "RF-Frequency";
catch ME
    warning('RF failed: %s', ME.message);
end

fprintf("\n[2/3] Training KNN on Freq Features...\n");
try
    freq_models{end+1} = fitcknn(Xtrain_freq, Ytrain_freq, "NumNeighbors", 3, "Standardize", true);
    freq_names{end+1} = "KNN-Frequency";
catch ME
    warning('KNN failed: %s', ME.message);
end

fprintf("\n[3/3] Training Decision Tree on Freq Features...\n");
try
    freq_models{end+1} = fitctree(Xtrain_freq, Ytrain_freq);
    freq_names{end+1} = "Tree-Frequency";
catch ME
    warning('Tree failed: %s', ME.message);
end

% Evaluate frequency-based models
fprintf("\n=== Frequency-Based Model Results ===\n");
for i = 1:length(freq_models)
    pred = predict(freq_models{i}, Xtest_freq);
    acc = sum(pred == Ytest_freq) / numel(Ytest_freq);
    fprintf("%s Accuracy: %.4f\n", freq_names{i}, acc);
    
    figure('Name', ['Confusion Matrix - ' char(freq_names{i})]);
    confusionchart(Ytest_freq, pred);
    title("Frequency Features - " + freq_names{i});
end
%% ==================================================
fprintf("\n=== Preprocessing Data ===\n");
% Replace NaNs with median (if any)
for c = 1:size(X,2)
    col = X(:,c);
    if any(isnan(col))
        col(isnan(col)) = median(col(~isnan(col)));
        X(:,c) = col;
    end
end

% Normalize
X = zscore(X);
%% ==================================================

%% ============= TRAIN / VALIDATION / TEST SPLIT =====
cv1 = cvpartition(Y, "HoldOut", testRatio);
Xtest = X(cv1.test, :);
Ytest = Y(cv1.test);

Xtemp = X(cv1.training, :);
Ytemp = Y(cv1.training);

cv2 = cvpartition(Ytemp, "HoldOut", valRatio / (1 - testRatio));
Xval = Xtemp(cv2.test, :);
Yval = Ytemp(cv2.test);

Xtrain = Xtemp(cv2.training, :);
Ytrain = Ytemp(cv2.training);

fprintf("Splits: Train=%d  Val=%d  Test=%d\n", size(Xtrain,1), size(Xval,1), size(Xtest,1));
%% ==================================================

%% ================= TRAIN 7 FAST MODELS ==================
fprintf("\n=== Training 7 Fast Classification Models ===\n");

models = {};
names = {}; % CHANGED TO CELL ARRAY

% 1. Naive Bayes (VERY FAST)
fprintf("\n[1/7] Training Naive Bayes...\n");
try
    models{end+1} = fitcnb(Xtrain, Ytrain);
    names{end+1} = "Naive Bayes";
catch ME
    warning('Naive Bayes failed: %s', ME.message);
end

% 2. Decision Tree (FAST)
fprintf("\n[2/7] Training Decision Tree...\n");
try
    models{end+1} = fitctree(Xtrain, Ytrain, "MaxNumSplits", 50);
    names{end+1} = "Decision Tree";
catch ME
    warning('Decision Tree failed: %s', ME.message);
end

% 3. Linear Discriminant Analysis (FAST)
fprintf("\n[3/7] Training Linear Discriminant...\n");
try
    models{end+1} = fitcdiscr(Xtrain, Ytrain, "DiscrimType", "linear");
    names{end+1} = "Linear Discriminant";
catch ME
    warning('LDA failed: %s', ME.message);
end

% 4. KNN (FAST - no optimization)
fprintf("\n[4/7] Training KNN...\n");
try
    models{end+1} = fitcknn(Xtrain, Ytrain, "NumNeighbors", 5, "Standardize", true);
    names{end+1} = "KNN";
catch ME
    warning('KNN failed: %s', ME.message);
end

% 5. Random Forest (MODERATE - reduced trees)
fprintf("\n[5/7] Training Random Forest...\n");
try
    models{end+1} = fitcensemble(Xtrain, Ytrain, "Method","Bag", "NumLearningCycles", 50);
    names{end+1} = "Random Forest";
catch ME
    warning('Random Forest failed: %s', ME.message);
end

% 6. AdaBoost (MODERATE - reduced cycles)
fprintf("\n[6/7] Training AdaBoost...\n");
try
    models{end+1} = fitcensemble(Xtrain, Ytrain, "Method", "AdaBoostM2", "NumLearningCycles", 50);
    names{end+1} = "AdaBoost";
catch ME
    warning('AdaBoost failed: %s', ME.message);
end

% 7. Quadratic Discriminant Analysis (FAST)
fprintf("\n[7/7] Training Quadratic Discriminant...\n");
try
    models{end+1} = fitcdiscr(Xtrain, Ytrain, "DiscrimType", "quadratic");
    names{end+1} = "Quadratic Discriminant";
catch
    try
        models{end+1} = fitcdiscr(Xtrain, Ytrain, "DiscrimType", "diaglinear");
        names{end+1} = "Diagonal Linear";
    catch ME
        warning('QDA failed: %s', ME.message);
    end
end

fprintf("\n=== %d Models Trained Successfully ===\n", length(models));
%% ==================================================

%% ================= EVALUATE ALL MODELS ==================
if isempty(models)
    error('No models were successfully trained. Check your data.');
end

allF1Scores = [];
allPrecision = [];
allRecall = [];
allAccuracy = [];
classes = categories(Ytest);

for i = 1:length(models)
    mdl = models{i};
    name = names{i};

    fprintf("\n====== %s RESULTS ======\n", name);

    try
        % Standard classifiers
        pred = predict(mdl, Xtest);

        % Confusion matrix
        C = confusionmat(Ytest, pred);
        
        % Accuracy
        acc = sum(pred == Ytest) / numel(Ytest);
        fprintf("Accuracy: %.4f\n", acc);
        allAccuracy(i) = acc;

        % Per-class metrics
        TP = diag(C);
        FP = sum(C,1)' - TP;
        FN = sum(C,2) - TP;

        precision = TP ./ (TP + FP);
        recall    = TP ./ (TP + FN);
        f1        = 2.*precision.*recall ./ (precision+recall);
        
        % Handle NaN values
        precision(isnan(precision)) = 0;
        recall(isnan(recall)) = 0;
        f1(isnan(f1)) = 0;

        % Store for visualization
        allF1Scores(:,i) = f1;
        allPrecision(:,i) = precision;
        allRecall(:,i) = recall;

        Tmetrics = table(classes, TP, FP, FN, precision, recall, f1);
        disp(Tmetrics);

        % Confusion chart
        figure('Name', ['Confusion Matrix - ' char(name)]); 
        confusionchart(Ytest, pred); 
        title("Confusion Matrix - " + name);
    catch ME
        warning('Evaluation failed for %s: %s', char(name), ME.message);
    end
end
%% ==================================================

%% ================= COMPREHENSIVE VISUALIZATIONS =================
fprintf("\n=== Creating Comprehensive Visualizations ===\n");

if ~isempty(allF1Scores)
    % 1. F1 Score Comparison - Grouped Bar Chart
    figure('Position', [50, 100, 1400, 600]);
    bar(allF1Scores);
    set(gca, 'XTickLabel', classes);
    xtickangle(45);
    legend(names, 'Location', 'bestoutside', 'FontSize', 9); % Now works with cell array
    ylabel('F1 Score', 'FontSize', 12);
    xlabel('Class', 'FontSize', 12);
    title('F1 Score Comparison Across All Models', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    ylim([0, 1.05]);

    % 2. Heatmap - F1 Scores
    figure('Position', [100, 100, 1000, 700]);
    h = heatmap(names, classes, allF1Scores, 'Colormap', jet, 'ColorLimits', [0, 1]);
    h.Title = 'F1 Score Heatmap - All Models';
    h.XLabel = 'Model';
    h.YLabel = 'Class';
    h.FontSize = 10;

    % 3. Precision, Recall, F1 Comparison
    figure('Position', [150, 100, 1600, 500]);

    subplot(1,3,1);
    bar(allPrecision);
    set(gca, 'XTickLabel', classes);
    xtickangle(45);
    legend(names, 'Location', 'bestoutside', 'FontSize', 8);
    ylabel('Score');
    title('Precision by Class');
    grid on;
    ylim([0, 1.05]);

    subplot(1,3,2);
    bar(allRecall);
    set(gca, 'XTickLabel', classes);
    xtickangle(45);
    legend(names, 'Location', 'bestoutside', 'FontSize', 8);
    ylabel('Score');
    title('Recall by Class');
    grid on;
    ylim([0, 1.05]);

    subplot(1,3,3);
    bar(allF1Scores);
    set(gca, 'XTickLabel', classes);
    xtickangle(45);
    legend(names, 'Location', 'bestoutside', 'FontSize', 8);
    ylabel('Score');
    title('F1 Score by Class');
    grid on;
    ylim([0, 1.05]);

    % 4. Overall Accuracy Comparison
    figure('Position', [200, 100, 1000, 500]);
    bar(allAccuracy, 'FaceColor', [0.2 0.6 0.8]);
    set(gca, 'XTickLabel', names);
    xtickangle(45);
    ylabel('Accuracy', 'FontSize', 12);
    title('Overall Model Accuracy Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    ylim([0, 1.05]);
    for k = 1:length(allAccuracy)
        text(k, allAccuracy(k)+0.03, sprintf('%.3f', allAccuracy(k)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    end

    % 5. Average F1 Score per Model
    figure('Position', [250, 100, 1000, 500]);
    avgF1 = mean(allF1Scores, 1);
    [sortedF1, sortIdx] = sort(avgF1, 'descend');
    bar(sortedF1, 'FaceColor', [0.8 0.4 0.2]);
    sortedNames = names(sortIdx); % Get sorted names
    set(gca, 'XTickLabel', sortedNames);
    xtickangle(45);
    ylabel('Average F1 Score', 'FontSize', 12);
    title('Average F1 Score Across All Classes (Sorted)', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    ylim([0, 1.05]);
    for k = 1:length(sortedF1)
        text(k, sortedF1(k)+0.03, sprintf('%.3f', sortedF1(k)), ...
            'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    end

    % 6. Per-Class Performance Summary
    figure('Position', [300, 100, 1400, 800]);
    numClasses = length(classes);
    numRows = ceil(numClasses/3);
    for c = 1:numClasses
        subplot(numRows, 3, c);
        classF1 = allF1Scores(c,:);
        bar(classF1, 'FaceColor', [0.3 0.7 0.5]);
        set(gca, 'XTickLabel', names);
        xtickangle(90);
        ylabel('F1 Score');
        title(classes{c}, 'FontWeight', 'bold');
        ylim([0, 1.05]);
        grid on;
    end
    sgtitle('F1 Score by Class and Model', 'FontSize', 14, 'FontWeight', 'bold');
end

%% ==================================================

fprintf("\n=== ALL VISUALIZATIONS AND TRAINING COMPLETED ===\n");
fprintf("Total Models Trained: %d\n", length(models));
if ~isempty(allAccuracy)
    [bestAcc, bestIdx] = max(allAccuracy);
    fprintf("Best Model (by accuracy): %s (%.4f)\n", names{bestIdx}, bestAcc);
end