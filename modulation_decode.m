% DSP Final Project (modulation)
% Author: Henry Troutman
filename = 'wavfiles/noise50p.wav';
freqs = 2.*pi.*([697,770,852,941,1209,1336,1477]);
keys = ['1','2','3';'4','5','6';'7','8','9';'*','0','#'];
fs = 8000;
% This quantity represents what fraction of the highest value the signal
% needs to be to qualify as silence
silence_diff_threshold = 5;
% read the file
[y,Fs] = audioread(filename);
% downsample if necessary
if Fs ~= fs
   disp('Mismatching sample rate, looking for 8kHz');
   if(Fs>fs)
       disp('decimating down')
      decimate(y,Fs/fs);
   else
       disp('quiting');
       stop;
   end
end

figure(1);
spectrogram(y,50,25,2048,fs,'yaxis');
% load an empty array
filtered_output = zeros(length(y),length(freqs));
% t values for the sin function at the sample rate
sine_domain = 0:1/fs:(length(y)/fs-1/fs);
temp = zeros(length(y),1);
% loop through each frequency and apply modulation and a filter
for i = 1:length(freqs)
   % When using the exact frequency, the output ends up
   % getting clipped below DC so +100 is added to keep it at dc
   modulation = 0.5*cos((freqs(i)+100).*sine_domain);
   signal_sum = y'.*modulation;
   % filter gets us closer to dc
   Hd = lp_mod_filter2();
   temp = filter(Hd,signal_sum);
   % remove negative component
   temp = temp.*temp;
   % use the movmean to get the DC offset
   filtered_output(:,i) = movmean(temp,200);
end
figure(2);
plot(filtered_output,'DisplayName','filtered_output');
% scale the threshold for different volume files
silence_threshold = max(max(filtered_output))/silence_diff_threshold;
guesses = [];
% These will store a count of each occurance where the frequency
% is the greatest of the 7
total1 = zeros(4,1);
total2 = zeros(3,1);
% state is used to find the falling edge when silence is reached
state = 0;
% loop through the time data
for i = 1:length(filtered_output)
    % check the sum of every filter against the threshold
    if sum(filtered_output(i,:)) < silence_threshold
        % silence is found
        if state == 0
            % this is not the first frame of silence
            % reset the data to prepare for the next tone
            total1 = zeros(4,1);
            total2 = zeros(3,1);
        else
            % this is the first frame of silence
            % store the data from the previous tone
            [m,f1] = max(total1);
            [m,f2] = max(total2);
            guesses = [guesses,keys(f1,f2)];
            state=0;
        end
        
    else
        % Determine which filter channel has the greatest value
        % for the upper and lower bands
        [m,f1] = max(filtered_output(i,1:4));
        [m,f2] = max(filtered_output(i,5:end));
        % increment the total value for each frequency
        total1(f1)=total1(f1)+1;
        total2(f2)=total2(f2)+1;
        % change the state to indicate that there is data to 
        % be stored
        state = 1;
        % Check if this is the last frame of the sound file
        if i==length(filtered_output)-1
            % store the final data since there may not be silence at 
            % the end of the file
            [m,f1] = max(total1);
            [m,f2] = max(total2);
            guesses = [guesses,keys(f1,f2)];
            state=0;
        end
    end
end
% Print the results
disp('Decoded DTMF Sequence (Modulation):');
disp(guesses);
