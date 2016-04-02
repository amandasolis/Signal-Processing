load('train_subject1_raw01.mat')

% Normalize data
X=(X - repmat(min(X,[],1),size(X,1),1))*spdiags(1./(max(X,[],1)-min(X,[],1))',0,size(X,2),size(X,2)); 

Electrodes={'Fp1', 'AF3', 'F7', 'F3', 'FC1', 'FC5', 'T7', 'C3','CP1', 'CP5', 'P7', 'P3', 'Pz', 'PO3', 'O1', 'Oz', 'O2', 'PO4', 'P4', 'P8', 'CP6', 'CP2', 'C4', 'T8', 'FC6', 'FC2', 'F4', 'F8', 'AF4', 'Fp2', 'Fz', 'Cz'};

fs=512; % Sampling frequency
T = 1/fs; % Sampling period


plot(X) % Plot electrode voltage drift over time
periodogram(X(:,1), [], [], fs); % Plot PSD Estimate to show line noise

%% Bandpass Filter the data (IIR Butterworth)
d = designfilt('bandpassiir','FilterOrder',20, ...
    'HalfPowerFrequency1',7,'HalfPowerFrequency2',30, ...
    'SampleRate',fs);
X=filtfilt(d,X); % zero phase filter
fvtool(d) % view filter

periodogram(X(:,1), [], [], fs); % Plot filtered data
xlim([0 50])

%% Split data into smaller data sets separated by task
ind2=find(Y==2);
ind3=find(Y==3);
ind7=find(Y==7);
left_movement=X(ind2,:); % array corresponding to left hand movement
right_movement=X(ind3,:); % array corresponding to right hand movement
word_generation=X(ind7,:); % array corresponding to random word generation

%% Compute PSD estimates of all channels for each task
[pxx_Right,f_Right] = periodogram(right_movement,[],[],fs);
[pxx_Left,f_Left] = periodogram(left_movement,[],[],fs);
[pxx_Word,f_Word] = periodogram(word_generation,[],[],fs);

%% Compute % Power
subband=[0 .1];
for n=1:340 
    for i=1:32
        L_pband = bandpower(pxx_Left(:,i),f_Left,subband,'psd');
        L_ptot = bandpower(pxx_Left(:,i),f_Left,'psd');
        per_power_L(n,i) = 100*(L_pband/L_ptot);

        R_pband = bandpower(pxx_Right(:,i),f_Right,subband,'psd');
        R_ptot = bandpower(pxx_Right(:,i),f_Right,'psd');
        per_power_R(n,i) = 100*(R_pband/R_ptot);

        W_pband = bandpower(pxx_Word(:,i),f_Word,subband,'psd');
        W_ptot = bandpower(pxx_Word(:,i),f_Word,'psd');
        per_power_W(n,i) = 100*(W_pband/W_ptot);
    end
    subband=subband+.1;
end

%% Plot % Total Power 
x=[.1:.1:34]';
figure;
clf

for i=1:32
    channel=i;
    formatSpec = 'Channel %1$s';
    str = sprintf(formatSpec,Electrodes{1,i});
    subplot(4,8,i)
    hold on;
    set(gca,'YScale','log') 
    plot(x,per_power_L(:,channel),'r')
    plot(x,per_power_R(:,channel),'b')
    plot(x,per_power_W(:,channel),'k')
    xlabel('Frequency (Hz)')
    ylabel('Percent Power')
    title(str);
    xlim([7 30])
    hold off
end
    legend('Left Hand','Right Hand','Word Generation')

%% Plot PSD estimate
for i=1:32
    channel=i;
    formatSpec = 'Channel %1$s';
    str = sprintf(formatSpec,Electrodes{1,i});
    subplot(4,8,i)
    hold on;
    plot(f_Left,10*log10(pxx_Left(:,channel)),'r')
    plot(f_Right,10*log10(pxx_Right(:,channel)),'b')
    plot(f_Word,10*log10(pxx_Word(:,channel)),'k')
    title(str);
    xlabel('Frequency (Hz)')
    ylabel('Power')
    xlim([7 30])
    hold off;
end
    legend('Left Hand','Right Hand','Word Generation')
   