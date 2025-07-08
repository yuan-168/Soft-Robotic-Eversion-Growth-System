% 获取 USB 设备信息
[~, usbInfo] = system('system_profiler SPUSBDataType');

% 打印 USB 设备信息
disp('USB Device Information:');
disp(usbInfo);

% 指定所需使用的摄像头的 USB 位置标识符
desiredUsbLocation1 = '  Location ID: 0x01100000 / 1'; % 示例 USB 位置标识符1
desiredUsbLocation2 = 'Location ID: 0x00100000 / 1'; % 示例 USB 位置标识符2

% 列出所有检测到的摄像头
camList = webcamlist;

% 查找指定 USB 位置标识符对应的摄像头索引
cam1Index = findCameraIndexByUsbLocation(desiredUsbLocation1, usbInfo);
cam2Index = findCameraIndexByUsbLocation(desiredUsbLocation2, usbInfo);

% 验证索引是否有效
if ~isempty(cam1Index) && ~isempty(cam2Index)
    % 创建摄像头对象
    cam1 = webcam(cam1Index);
    cam2 = webcam(cam2Index);

    % 设置分辨率
    cam1.Resolution = '1280x720';
    cam2.Resolution = '1280x720';

    img1 = snapshot(cam1);
    img2 = snapshot(cam2);

    % 创建视频播放器
    videoPlayer = vision.VideoPlayer('Position', [100, 100, 2560, 720]);

    % 创建视频文件写入对象
    writerObj = VideoWriter('merged_output.avi', 'Motion JPEG AVI');
    writerObj.FrameRate = 30;
    open(writerObj);

    % 录制视频的持续时间（秒）
    recordingDuration = 10; 
    tic;

    % 记录尖端位置和时间的数组
    tip_positions = [];
    tip_times = [];

    load('stereoParams.mat');

    while toc < recordingDuration
        % 捕获一帧图像
        frame1 = snapshot(cam1);
        frame2 = snapshot(cam2);

        % 合并两帧图像
        mergedFrame = [frame1, frame2];

        % 显示合并后的图像
        step(videoPlayer, mergedFrame);

        % 将合并后的帧写入视频文件
        writeVideo(writerObj, mergedFrame);

        % 检测尖端位置
        [tipleft_2D,  tipright_2D] = detecttip(frame1, frame2);

        % 记录尖端位置和时间
        if ~isempty(tipleft_2D) && ~isempty(tipright_2D)
            tip_positions = [tipleft_2D; tipright_2D];
            tip_times = [tip_times; toc];
        end
    end

    % 计算3D坐标和速度
    if size(tip_positions, 1) > 1
        [robot_tip, speeds] = calculate3DCoordinatesAndSpeed(tip_positions, tip_times, stereoParams);
        disp('3D Coordinates and Speeds:');
        disp(robot_tip);
        disp(speeds);
    else
        disp('Insufficient data points for 3D coordinate calculation.');
    end

    % 释放资源
    release(videoPlayer);
    close(writerObj);
    clear cam1;
    clear cam2;
else
    error('One or both desired cameras not found.');
end

% 自定义函数：根据 USB 位置标识符查找摄像头索引
function camIndex = findCameraIndexByUsbLocation(desiredUsbLocation, usbInfo)
    % 将 USB 信息按行分割
    usbLines = strsplit(usbInfo, '\n');
    camIndex = [];
    % 遍历每一行，查找包含指定 USB 位置标识符的行
    for i = 1:length(usbLines)
        if contains(usbLines{i}, desiredUsbLocation)
            % 一旦找到匹配的 USB 位置标识符，查找相应的摄像头名称
            for j = i:length(usbLines)
                if contains(usbLines{j}, 'Product ID')
                    % 获取摄像头名称（假设与 Product ID 行在同一块中）
                    productName = strtrim(strsplit(usbLines{j-1}, ':'){2});
                    % 查找该摄像头名称在摄像头列表中的索引
                    camList = webcamlist;
                    camIndex = find(strcmp(camList, productName));
                    return;
                end
            end
        end
    end
end

% 检测尖端位置的函数
function [tipleft_2D,  tipright_2D] = detecttip(frame1, frame2)
    % 将 RGB 图像转换为 HSV 颜色空间
    frame_hsv1 = rgb2hsv(frame1);
    frame_hsv2 = rgb2hsv(frame2);

    % 定义绿色的 HSV 范围
    hueThresholdLow = 0.2;
    hueThresholdHigh = 0.5;
    saturationThresholdLow = 0.3;
    saturationThresholdHigh = 1.0;
    valueThresholdLow = 0.1;
    valueThresholdHigh = 1.0;

    % 创建绿色掩码
    green_mask1 = (frame_hsv1(:,:,1) >= hueThresholdLow) & (frame_hsv1(:,:,1) <= hueThresholdHigh) & ...
                  (frame_hsv1(:,:,2) >= saturationThresholdLow) & (frame_hsv1(:,:,2) <= saturationThresholdHigh) & ...
                  (frame_hsv1(:,:,3) >= valueThresholdLow) & (frame_hsv1(:,:,3) <= valueThresholdHigh);
    green_mask2 = (frame_hsv2(:,:,1) >= hueThresholdLow) & (frame_hsv2(:,:,1) <= hueThresholdHigh) & ...
                  (frame_hsv2(:,:,2) >= saturationThresholdLow) & (frame_hsv2(:,:,2) <= saturationThresholdHigh) & ...
                  (frame_hsv2(:,:,3) >= valueThresholdLow) & (frame_hsv2(:,:,3) <= valueThresholdHigh);

    % 将掩码应用到原始图像
    green_segmented1 = bsxfun(@times, frame1, cast(green_mask1, 'like', frame1));
    green_segmented2 = bsxfun(@times, frame2, cast(green_mask2, 'like', frame2));

    % 提取骨干
    se = strel('line', 25, 90);
    erodedBW_1 = imerode(green_segmented1, se);
    erodedBW_2 = imerode(green_segmented2, se);

    % 将绿色分割后的图像转换为灰度图像并二值化
    green_segmented_gray1 = rgb2gray(green_segmented1);
    binary_image1 = imbinarize(green_segmented_gray1);
    green_segmented_gray2 = rgb2gray(green_segmented2);
    binary_image2 = imbinarize(green_segmented_gray2);

    % 查找二值图像中像素值为1的坐标点
    [y1, x1] = find(binary_image1);
    [y2, x2] = find(binary_image2);

    % 初始化返回值
    tipleft_2D = [];
    tipright_2D = [];

    % 如果找到了有效的点
    if ~isempty(x1) && ~isempty(y1)
        % 找到最小的 y 坐标点
        [y1_min, idx1] = min(y1);
        tipleft_2D = [x1(idx1), y1_min];
    end

    if ~isempty(x2) && ~isempty(y2)
        % 找到最小的 y 坐标点
        [y2_min, idx2] = min(y2);
        tipright_2D = [x2(idx2), y2_min];
    end
end

% 计算3D坐标和速度的函数
function [robot_tip, speeds] = calculate3DCoordinatesAndSpeed(tip_positions, tip_times, stereoParams)
    % 使用 stereoParams 进行三角测量计算 3D 坐标
    
    robot_tip = zeros(num_points, 3);
    for i = 1:2
        robot_tip(i, :) = triangulate(tip_positions(i, :), stereoParams);
    end

    % 计算速度
    speeds = zeros(num_points-1, 3);
    for i = 2:num_points
        delta_t = tip_times(i) - tip_times(i-1);
        delta_pos = robot_tip(i, :) - robot_tip(i-1, :);
        speeds(i-1, :) = delta_pos / delta_t;
    end
end
