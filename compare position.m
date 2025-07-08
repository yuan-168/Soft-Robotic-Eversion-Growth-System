file_paths = { ...
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/120KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/130KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/140KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/150KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/160KPa_V60.txt' ...
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/120KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/130KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/140KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/150KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/160KPa_V60.txt' ...
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/120KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/130KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/140KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/150KPa_V60.txt', ...
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/160KPa_V60.txt' ...
};
y_limits = zeros(length(file_paths), 2);

colors_original = [
    [237/255, 173/255, 197/255];
    [206/255, 170/255, 208/255];
    [149/255, 132/255, 193/255];
    [108/255, 190/255, 195/255];
    [97/255, 156/255, 217/255]
];

saturation_increase = 0.2;
colors_saturated = zeros(size(colors_original));

for i = 1:size(colors_original, 1)
    
    hsv = rgb2hsv(colors_original(i, :));
    hsv(2) = min(hsv(2) + saturation_increase, 1); 
    
    colors_saturated(i, :) = hsv2rgb(hsv);
end
figure;
hold on; 

line_widths = zeros(15, 1);

line_styles = {'-', '--', ':', '-.', '-', '-', '--', ':', '-.', '-', '-', '--', ':', '-.', '-',};


for file_index = 1:length(file_paths)
    filename = file_paths{file_index};
    
    [~, file_name, ~] = fileparts(filename);  
    
    fileID = fopen(filename, 'r');
    data = textscan(fileID, '%s %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', 1);
    fclose(fileID);
    time_str = data{1};
    x = data{2}; 
    y = data{3}; 
    z = data{4}; 

    for i = 2:length(x)
        if x(i) == 0 && y(i) == 0 && z(i) == 0
           
            x(i) = x(i-1);
            y(i) = y(i-1);
            z(i) = z(i-1);
        end
    end
    initial_point = [x(1), y(1), z(1)];
    distance_from_initial = sqrt((x - initial_point(1)).^2 + (y - initial_point(2)).^2 + (z - initial_point(3)).^2);
    time = datetime(time_str, 'InputFormat', 'HH:mm:ss.SSS');
    time_seconds = seconds(time - time(1));
    extend_len = 10;
    first_five = repmat(distance_from_initial(1), extend_len, 1);
    last_five = repmat(distance_from_initial(end), extend_len, 1);
    padded_data = [first_five; distance_from_initial];
    padded_data = [padded_data; last_five];
    cutoff_frequency = 0.01; 
    smoothed_distance = lowpass(padded_data, cutoff_frequency, 1/dt);
    smoothed_distance = smoothed_distance(extend_len+1:end - extend_len);
    
    smoothed_distance = smoothed_distance - smoothed_distance(1);
    
    time_end = time_seconds(end);
    time_start = time_end - 60;
    indices = time_seconds >= time_start & time_seconds <= time_end;
    shortened_time_seconds = time_seconds(indices);
    shortened_smoothed_distance = smoothed_distance(indices);
    shortened_time_seconds = shortened_time_seconds - shortened_time_seconds(1);
    line_style = line_styles{mod(file_index-1, length(line_styles)) + 1};
    
    if file_index <= 5
        legend_label = sprintf('%s: 30um thick', file_name);
        line_widths(file_index) = 2; 
    elseif file_index <= 10
        legend_label = sprintf('%s: 40um thick', file_name);
        line_widths(file_index) = 3; 
    else
        legend_label = sprintf('%s: 50um thick', file_name);
        line_widths(file_index) = 4;
    end
    
    plot(shortened_time_seconds, shortened_smoothed_distance, 'LineWidth', line_widths(file_index), ...
         'Color', colors_saturated(mod(file_index-1, length(colors_saturated))+1, :), ...
         'LineStyle', line_style, 'DisplayName', legend_label);
end

xlabel('Time (seconds)');
ylabel('Grow Length');
title('Grow Length for different pressure');

legend('show', 'FontWeight', 'bold', 'Location', 'best', 'FontSize', 12, 'Box', 'off'); 

grid on;  
hold off;  
