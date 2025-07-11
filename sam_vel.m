% 文件路径和对应的标签
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

% 创建一个包含 5 个数据集的图形窗口
% figure;
% hold on;  % 保持图形窗口，以便绘制多个数据集

% 用于存储不同的纵坐标轴范围
y_limits = zeros(length(file_paths), 2);

% 原始颜色数组 (RGB)
colors_original = [
    [237/255, 173/255, 197/255];
    [206/255, 170/255, 208/255];
    [149/255, 132/255, 193/255];
    [108/255, 190/255, 195/255];
    [97/255, 156/255, 217/255]
];

% 增加饱和度20%
saturation_increase = 0.2;
colors_saturated = zeros(size(colors_original));

for i = 1:size(colors_original, 1)
    % 转换RGB到HSV
    hsv = rgb2hsv(colors_original(i, :));
    
    % 增加饱和度
    hsv(2) = min(hsv(2) + saturation_increase, 1); % 确保饱和度不超过1
    
    % 转换回RGB
    colors_saturated(i, :) = hsv2rgb(hsv);
end

% 绘制图形
figure;
hold on;  % 保持图形窗口，以便绘制多个数据集

line_widths = zeros(15, 1);

% 定义15种线型
line_styles = {'-', '--', ':', '-.', '-', '-', '--', ':', '-.', '-', '-', '--', ':', '-.', '-',};

% 遍历每个数据文件
for file_index = 1:length(file_paths)
    filename = file_paths{file_index};
    
    % 从文件路径中提取标签
    [~, file_name, ~] = fileparts(filename);  % 获取文件名（不带扩展名）
    
    % 读取数据文件
    fileID = fopen(filename, 'r');
    data = textscan(fileID, '%s %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', 1);
    fclose(fileID);

    % 提取时间和坐标数据
    time_str = data{1};
    x = data{2}; % 直接提取
    y = data{3}; % 直接提取
    z = data{4}; % 直接提取

    % 替换坐标为零的点
    for i = 2:length(x)
        if x(i) == 0 && y(i) == 0 && z(i) == 0
            % 用前一个有效的位置数据替换
            x(i) = x(i-1);
            y(i) = y(i-1);
            z(i) = z(i-1);
        end
    end

    % 计算到初始点的距离
    initial_point = [x(1), y(1), z(1)];
    distance_from_initial = sqrt((x - initial_point(1)).^2 + (y - initial_point(2)).^2 + (z - initial_point(3)).^2);

    % 将时间字符串转换为秒数
    time = datetime(time_str, 'InputFormat', 'HH:mm:ss.SSS');
    time_seconds = seconds(time - time(1));

    % 设置延拓长度
    extend_len = 10;

    % 取前十个数
    first_five = repmat(distance_from_initial(1), extend_len, 1);

    % 取后十个数
    last_five = repmat(distance_from_initial(end), extend_len, 1);

    % 重复前个数并拼接到开头
    padded_data = [first_five; distance_from_initial];

    % 重复后个数并拼接到结尾
    padded_data = [padded_data; last_five];

    % 应用低通滤波器平滑距离数据
    cutoff_frequency = 0.01; 
    smoothed_distance = lowpass(padded_data, cutoff_frequency, 1/dt);

    % 去除延拓部分，得到滤波后的数据
    smoothed_distance = smoothed_distance(extend_len+1:end - extend_len);
    
    % 使平滑后的距离从0开始
    smoothed_distance = smoothed_distance - smoothed_distance(1);
    
    % 确保时间范围在 [end-60, end] 内
    time_end = time_seconds(end);
    time_start = time_end - 60;
    
    % 找到对应 [end-60, end] 的索引范围
    indices = time_seconds >= time_start & time_seconds <= time_end;

    % 缩短时间和距离数据
    shortened_time_seconds = time_seconds(indices);
    shortened_smoothed_distance = smoothed_distance(indices);

    % 将 `time_start-1` 设置为新的起点
    shortened_time_seconds = shortened_time_seconds - shortened_time_seconds(1);

    % 每个数据集使用不同的线型
    line_style = line_styles{mod(file_index-1, length(line_styles)) + 1};
    
    % 生成图例标签
    if file_index <= 5
        legend_label = sprintf('%s: 30um thick', file_name);
        line_widths(file_index) = 2; % 第1-5个文件，线宽为2
    elseif file_index <= 10
        legend_label = sprintf('%s: 40um thick', file_name);
        line_widths(file_index) = 3; % 第6-10个文件，线宽为3
    else
        legend_label = sprintf('%s: 50um thick', file_name);
        line_widths(file_index) = 4; % 第11-15个文件，线宽为4
    end
    
    % 绘制数据（使用指定颜色、线宽和线型）
    plot(shortened_time_seconds, shortened_smoothed_distance, 'LineWidth', line_widths(file_index), ...
         'Color', colors_saturated(mod(file_index-1, length(colors_saturated))+1, :), ...
         'LineStyle', line_style, 'DisplayName', legend_label);
end

% 添加图例和标签
xlabel('Time (seconds)');
ylabel('Grow Length');
title('Grow Length for different pressure');

% 自定义图例
legend('show', 'FontWeight', 'bold', 'Location', 'best', 'FontSize', 12, 'Box', 'off'); % 显示图例并设置字体加粗，位置为最佳，字体大小为12，去掉图例边框

grid on;  % 添加网格
hold off;  % 释放图形窗口
