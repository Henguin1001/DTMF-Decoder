% DSP Final Project (Filter bank)
% Author: Henry Troutman
filename = 'wavfiles/noise50p.wav';
freqs = [697,770,852,941,1209,1336,1477];
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
filtered_output = zeros(length(y),length(freqs));
% loop through each frequency and apply a bandpass filter
temp = zeros(length(y),1);
% ripple and stop gain
Rp = 3;
Rs = 40;
for i = 1:length(freqs)
   % Stop +- 25 Hz from the desired frequency
   Hd = myfilter(freqs(i)-25,freqs(i)+25);
   temp = filter(Hd,y);
   % remove negative component
   temp = temp.*temp;
   % smooth the wave with an average
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
disp('Decoded DTMF Sequence (Filter Bank):');
disp(guesses);