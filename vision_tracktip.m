clc;
close all;
clear all;

% camera initialization and setup
webcamList = webcamlist;
disp('Connected cameras:');
disp(webcamList);

% Identify indices for the 'HD USB Camera'
hdUsbCameraIndices = find(strcmp(webcamList, 'HD USB Camera'));

% Check if there are at least two 'HD USB Camera'
if length(hdUsbCameraIndices) < 2
    error('Not enough HD USB Cameras found.');
end

% Create webcam objects
videoReader_1 = webcam(hdUsbCameraIndices(1));
videoReader_1.Resolution = '1920x1080';
videoReader_2 = webcam(hdUsbCameraIndices(2));
videoReader_2.Resolution = '1920x1080';

figure;  % Create a new figure window
h1 = subplot(1,2,1);
h2 = subplot(1,2,2);

while (1)
    frame_1 = snapshot(videoReader_1);  % Read frame from cam1
    frame_2 = snapshot(videoReader_2);  % Read frame from cam2
    
    frame_l = trackgreen(frame_1);
    frame_r = trackgreen(frame_2);
    
    % Update the displayed images
    subplot(1,2,1), imshow(frame_l, 'Parent', h1);  % Display processed frame from cam1
    subplot(1,2,2), imshow(frame_r, 'Parent', h2);  % Display processed frame from cam2
end

function processed_frame = trackgreen(frame)

    % Define green HSV threshold range
    hueThresholdLow = 0.2;
    hueThresholdHigh = 0.5;
    saturationThresholdLow = 0.3;
    saturationThresholdHigh = 1.0;
    valueThresholdLow = 0.1;
    valueThresholdHigh = 1.0;

    % 将 RGB 图像转换为 HSV 颜色空间
    frame_hsv = rgb2hsv(frame);  % Convert RGB image to HSV color space

    % Create green mask
    green_mask = (frame_hsv(:,:,1) >= hueThresholdLow) & (frame_hsv(:,:,1) <= hueThresholdHigh) & ...
                 (frame_hsv(:,:,2) >= saturationThresholdLow) & (frame_hsv(:,:,2) <= saturationThresholdHigh) & ...
                 (frame_hsv(:,:,3) >= valueThresholdLow) & (frame_hsv(:,:,3) <= valueThresholdHigh);

    % Apply mask to original image
    green_segmented = bsxfun(@times, frame, cast(green_mask, 'like', frame));

    % Convert segmented green image to grayscale and binarize
    green_segmented_gray = rgb2gray(green_segmented);
    binary_image = imbinarize(green_segmented_gray);

    % Find coordinates of pixels with value 1 in binary image
    [y, x] = find(binary_image);

    % If valid points are found
    if ~isempty(x) && ~isempty(y)
        % Find the minimum y-coordinate point
        [y_min, idx] = min(y);
        tip_position = [x(idx), y_min];

        % Mark tip position on the original frame
        processed_frame = insertMarker(frame, tip_position, 'Color', 'red', 'Size', 30);
    else
        tip_position = [];
        disp('No green region detected.');
        processed_frame = frame;  % Return original frame without any changes
    end
end