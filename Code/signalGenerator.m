clear; clc; close all;
fprintf('=== General Signal Generator ===\n\n');

%% =========================
%% 1. GLOBAL PARAMETERS
%% =========================
fs = input('Enter sampling frequency (Hz): ');
while fs <= 0
    fs = input('Must be > 0! Enter sampling frequency: ');
end

t_start = input('Enter start time: ');
t_end   = input('Enter end time: ');
while t_start >= t_end
    t_start = input('Start must be < End! Enter start: ');
    t_end   = input('Enter end: ');
end

dt = 1/fs;
t_total = t_start:dt:t_end;

%% =========================
%% 2. BREAKPOINTS
%% =========================
num_bp = input('Enter number of breakpoints: ');
while num_bp < 0 || num_bp ~= floor(num_bp)
    num_bp = input('Must be non-negative integer! Enter again: ');
end

breakpoints = [];
if num_bp > 0
    fprintf('Enter breakpoint positions:\n');
    for i = 1:num_bp
        bp = input(sprintf('Breakpoint %d: ', i));
        while bp <= t_start || bp >= t_end
            bp = input('Must be inside range! Enter again: ');
        end
        breakpoints = [breakpoints bp];
    end
    breakpoints = unique(sort(breakpoints));
end

all_breaks = [t_start breakpoints t_end];
num_regions = length(all_breaks) - 1;

%% =========================
%% 3. GENERATE SIGNAL
%% =========================
y_total = zeros(size(t_total));

for r = 1:num_regions
    
    fprintf('\n--- Region %d [%.2f -> %.2f] ---\n', ...
        r, all_breaks(r), all_breaks(r+1));
    
    % region time
    if r < num_regions
        idx = t_total >= all_breaks(r) & t_total < all_breaks(r+1);
    else
        idx = t_total >= all_breaks(r) & t_total <= all_breaks(r+1);
    end
    
    t_region = t_total(idx);
    
    %% choose signal
    disp('1=DC  2=Ramp  3=Polynomial  4=Exponential  5=Sinusoidal');
    type = input('Enter choice: ');
    
    while type < 1 || type > 5
        type = input('Invalid! Enter (1-5): ');
    end
    
    %% generate region signal
    switch type
        
        case 1 % DC
            A = input('Amplitude: ');
            y_region = A * ones(size(t_region));
            
        case 2 % Ramp
            m = input('Slope: ');
            b = input('Intercept: ');
            y_region = m*t_region + b;
            
        case 3 % Polynomial
            a = input('Amplitude: ');
            n = input('Power: ');
            b = input('Intercept: ');
            y_region = a*(t_region.^n) + b;
            
        case 4 % Exponential
            A = input('Amplitude: ');
            k = input('Exponent: ');
            y_region = A * exp(k*t_region);
            
        case 5 % Sinusoidal
            A = input('Amplitude: ');
            f = input('Frequency: ');
            phi = input('Phase: ');
            y_region = A * sin(2*pi*f*t_region + phi);
    end
    
    % assign to full signal
    y_total(idx) = y_region;
end

%% =========================
%% 4. ORIGINAL PLOT
%% =========================
figure;
plot(t_total, y_total, 'LineWidth', 2);
grid on;
title('Original Signal');
xlabel('Time');
ylabel('Amplitude');

%% =========================
%% 5. OPERATIONS 
%% =========================
% Start with the original generated signal
y_new = y_total;
t_new = t_total;

while true
    disp('Choose Operation:');
    disp('1-Amplitude Scaling');
    disp('2-Time Reversal');
    disp('3-Time Shift');
    disp('4-Expansion');
    disp('5-Compression');
    disp('6-None');
    op_id = input('Enter operation: ');
    
    if op_id == 1
        op_val = input('Enter scaling value: ');
    elseif op_id == 3
        op_val = input('Enter shift value: ');
    elseif op_id == 4
        op_val = input('Enter expansion factor: ');
    elseif op_id == 5
        op_val = input('Enter compression factor: ');
    else
        op_val = 0;
    end
    
    [y_new, t_new] = operation(y_new, t_new, op_id, op_val);
    
    %% =========================
    %% 6. SIGNAL PROPERTIES
    %% =========================
    tol = 1e-6;
    % 1. Symmetry Check (Even/Odd)
    t_min = t_new(1);
    t_max = t_new(end);
    is_even = false;
    is_odd = false;
    if abs(t_min + t_max) < tol
        y_flipped = flip(y_new);
        if all(abs(y_new - y_flipped) < tol)
            is_even = true;
        end
        if all(abs(y_new + y_flipped) < tol)
            is_odd = true;
        end
    end
    %% -------- Causality --------
    is_causal = all(abs(y_new(t_new < 0)) < tol);
    %% -------- PRINT --------
    fprintf('\nSignal Properties: ');
    if is_even
        fprintf('Even, ');
    elseif is_odd
        fprintf('Odd, ');
    else
        fprintf('Neither Even nor Odd, ');
    end
    if is_causal
        fprintf('Causal, ');
    else
        fprintf('Non-Causal, ');
    end
    
    %% =========================
    %% 7. ENERGY CALCULATION
    %% =========================
    dt = diff(t_new);
    E = sum(abs(y_new(1:end-1)).^2 .* dt);
    fprintf('\nSignal Energy = %.6f\n', E);
    
    %% Ask for another operation
    another = input('\nDo you want to perform another operation? (1 = Yes, 0 = No): ');
    if another == 0
        break;  % exit the loop
    end
end

%% =========================
%% 7. OPERATIONS FUNCTION
%% =========================
function [sig_out, t_out] = operation(sig_in, t_in, op_id, op_val)
switch op_id
case 1 % Amplitude Scaling
        sig_out = sig_in * op_val;
        t_out = t_in;
case 2 % Time Reversal
        sig_out = flip(sig_in);
        t_out = -flip(t_in);
case 3 % Time Shift
        t_out = t_in + op_val;
        sig_out = sig_in;
case 4 % Expansion
        t_out = linspace(t_in(1), t_in(end), length(sig_in)*op_val);
        sig_out = interp1(t_in, sig_in, t_out, 'linear', 0);
case 5 % Compression
        t_out = linspace(t_in(1), t_in(end), floor(length(sig_in)/op_val));
        sig_out = interp1(t_in, sig_in, t_out, 'linear', 0);
case 6 % None
        sig_out = sig_in;
        t_out = t_in;
otherwise
        error('Invalid operation');
end
%% plotting
figure;
subplot(2,1,1);
plot(t_in, sig_in, 'LineWidth',2);
title('Input Signal'); grid on;
subplot(2,1,2);
plot(t_out, sig_out, 'LineWidth',2);
title('Output Signal'); grid on;
end
