
clear; clc;
fprintf('=== general signal generator ===\n\n');

%% 1. global parameters
fs = input('enter sampling frequency (hz): ');
while fs <= 0
    fs = input('must be > 0! enter sampling frequency (hz): ');
end

tstart = input('enter start of time scale: ');
tend = input('enter end of time scale: ');
while tstart >= tend
    tstart = input('start must be < end! enter start time: ');
    tend = input('enter end time: ');
end

%% 2. breakpoints
numbp = input('enter number of break points: ');
while numbp < 0 || numbp ~= floor(numbp)
    numbp = input('must be non-negative integer! enter number: ');
end

breakpoints = [];
if numbp > 0
    fprintf('enter %d breakpoint position(s):\n', numbp);
    for i = 1:numbp
        bp = input(sprintf(' breakpoint %d: ', i));
        while bp <= tstart || bp >= tend
            bp = input(' must be strictly inside time scale! enter again: ');
        end
        breakpoints = [breakpoints bp];
    end
    breakpoints = unique(sort(breakpoints)); % auto-sort + remove duplicates
end

%% 3. define regions
allbreaks = [tstart, breakpoints, tend];
numregions = length(allbreaks) - 1;
dt = 1/fs;
ttotal = tstart : dt : tend; % master time vector

regiont = cell(1, numregions);
for i = 1:numregions
    startreg = allbreaks(i);
    endreg = allbreaks(i+1);
    if i < numregions
        idx = ttotal >= startreg & ttotal < endreg;
    else
        idx = ttotal >= startreg & ttotal <= endreg;
    end
    regiont{i} = ttotal(idx);
end

%% 4. signal specifications for each region
signalspecs = struct('type', cell(1,numregions), 'params', cell(1,numregions));

for r = 1:numregions
    fprintf('\n--- region %d [%.3f → %.3f] ---\n', r, allbreaks(r), allbreaks(r+1));
   
    choice = input(['signal type?\n' ...
                    '1=dc 2=ramp 3=polynomial 4=exponential 5=sinusoidal\n' ...
                    'choice (1-5): ']);
    while choice < 1 || choice > 5 || choice ~= floor(choice)
        choice = input('invalid! choice (1-5): ');
    end
   
    switch choice
        case 1 % dc
            typestr = 'dc';
            amp = input('amplitude: ');
            params = struct('amplitude', amp);
           
        case 2 % ramp
            typestr = 'ramp';
            slope = input('slope: ');
            intercept = input('intercept: ');
            params = struct('slope', slope, 'intercept', intercept);
           
        case 3 % polynomial
            typestr = 'polynomial';
            amp = input('amplitude: ');
            power = input('power: ');
            intercept = input('intercept: ');
            params = struct('amplitude', amp, 'power', power, 'intercept', intercept);
           
        case 4 % exponential
            typestr = 'exponential';
            amp = input('amplitude: ');
            exponent = input('exponent: ');
            params = struct('amplitude', amp, 'exponent', exponent);
           
        case 5 % sinusoidal
            typestr = 'sinusoidal';
            amp = input('amplitude: ');
            freq = input('frequency: ');
            while freq < 0
                freq = input('frequency >= 0! enter again: ');
            end
            phase = input('phase: ');
            params = struct('amplitude', amp, 'frequency', freq, 'phase', phase);
    end
   
    signalspecs(r).type = typestr;
    signalspecs(r).params = params;
end

%% ready for member 2
fprintf('\ndone! %d regions created.\n', numregions);
disp(' • ttotal, regiont, signalspecs, fs, tstart, tend');

% just continue or run member 2 code now