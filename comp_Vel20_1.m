% 文件路径和对应的标签
file_paths = { 
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/140KPa_V20.txt',
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/150KPa_V20.txt',
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/150KPa_V20.txt',
    '/Users/shiyuanwang/Documents/001 individual project/project/30/30um/160KPa_V20.txt',
    '/Users/shiyuanwang/Documents/001 individual project/project/40/40um/160KPa_V20.txt',
    '/Users/shiyuanwang/Documents/001 individual project/project/50/Tip Tracking/160KPa_V20.txt' 
};
% 定义15种线型
line_styles = {'-', '-', '-', '-','-','-','-',':',':','-.', '-', '-', '-', '-', '-', '-',};
line_widths = {2,2,2,2,2,2,2,2,2};
% 默认标签列表
default_labels = {
    '30um-140KPa-vel20',
    '30um-150KPa-vel20',
    '40um-150KPa-vel20',
    '30um-160KPa-vel20',
    '40um-160KPa-vel20',
    '50um-160KPa-vel20',   
};

% 创建一个包含 6 个数据集的图形窗口
figure;
hold on;  % 保持图形窗口，以便绘制多个数据集

% 定义颜色数组 (RGB)
colors = [
    
    [237/255,173/255,197/255]; 
    [206/255, 170/255, 208/255];
    [149/255, 132/255, 193/255];
    [108/255, 190/255, 195/255];
    [170/255, 215/255, 200/255];
    [97/255, 156/255, 217/255];

];

% 遍历每个数据文件
for file_index = 1:length(file_paths)
    filename = file_paths{file_index};
    
    % 从文件路径中提取标签
    
    label = default_labels{file_index};  % 如果没有匹配，使用默认标签
    

    % 尝试打开文件
    fileID = fopen(filename, 'r');
    
    if fileID == -1
        error('Error opening file: %s', filename);  % 显示出错的文件名
    end
    
    % 读取数据文件
    data = textscan(fileID, '%s %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', 1);
    fclose(fileID);

    % 提取时间和坐标数据
    time_str = data{1};
    x = data{2};
    y = data{3};
    z = data{4};

    % 替换坐标为零的点
    for i = 2:length(x)
        if x(i) == 0 && y(i) == 0 && z(i) == 0
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
    first_ten = repmat(distance_from_initial(1), extend_len, 1);

    % 取后十个数
    last_ten = repmat(distance_from_initial(end), extend_len, 1);

    % 重复前个数并拼接到开头
    padded_data = [first_ten; distance_from_initial];

    % 重复后个数并拼接到结尾
    padded_data = [padded_data; last_ten];

    % 应用低通滤波器平滑距离数据
    dt = mean(diff(time_seconds));  % 计算平均采样间隔
    cutoff_frequency = 0.01; 
    smoothed_distance = lowpass(padded_data, cutoff_frequency, 1/dt);

    % 计算速度（简单的有限差分法），使用平滑后的距离数据
    num_points = length(smoothed_distance);
    computed_speed = diff(smoothed_distance) / dt;

    % 再次应用低通滤波器平滑速度数据
    cutoff_frequency1 = 0.0005; 
    smoothed_speed = lowpass(computed_speed, cutoff_frequency1, 1/dt);

    % 去除延拓部分，得到滤波后的数据
    smoothed_speed = smoothed_speed(extend_len+1:end-extend_len);
    time_seconds = time_seconds(1:end-1);  % 调整时间数组长度以匹配速度数据

    % 确保时间范围在 [end-60, end] 内
    time_end = time_seconds(end);
    time_start = time_end - 60;
    
    % 找到对应 [end-60, end] 的索引范围
    indices = time_seconds >= time_start & time_seconds <= time_end;

    % 缩短时间和速度数据
    shortened_time_seconds = time_seconds(indices) - time_start;
    shortened_smoothed_speed = smoothed_speed(indices);
    % 每个数据集使用不同的线型
    line_style = line_styles{mod(file_index-1, length(line_styles)) + 1};
    line_width = line_widths{mod(file_index-1, length(line_widths)) + 1};
    
    % 绘制数据（使用指定颜色）
    plot(shortened_time_seconds, shortened_smoothed_speed, 'LineWidth', line_width, ...
         'Color', colors(file_index, :), ...
         'LineStyle', line_style, 'DisplayName', label);
end

% 添加图例和标签
xlabel('Time (seconds)');
ylabel('Grow Speed （mm/s）');
title('Grow Speed for Different Pressure and Thickness');
legend('show', 'FontWeight', 'bold'); % 显示图例并设置字体加粗
grid on;  % 添加网格
hold off;  % 释放图形窗口

savefig('/Users/shiyuanwang/Documents/001 individual project/project/velocity/vel20-plot.fig');
