function colorize_video_temporal(inputVideoPath, outputVideoPath, refImgPath)
   

    % Load input video
    vidReader = VideoReader("C:\Users\brend\OneDrive\Desktop\DIP\grayscale_vid.mp4");
    fps = vidReader.FrameRate;
    vidWriter = VideoWriter("coloured.mp4", 'MPEG-4');
    vidWriter.FrameRate = fps;
    open(vidWriter);

    % Load and preprocess reference image (resized for uniformity)
    refImg = im2double(imread("C:\Users\brend\OneDrive\Desktop\DIP\reference2.png"));
    refLab = rgb2lab(imresize(refImg, [256 256]));
    ref_mean_ab = mean(reshape(refLab(:,:,2:3),[],2),1);
    ref_std_ab = std(reshape(refLab(:,:,2:3),[],2),0,1);

    prevGray = [];
    lastFrameF = [];
    frameCount = 0;

    while hasFrame(vidReader)
        frame = readFrame(vidReader);
        grayFrame = im2double(rgb2gray(frame));
        frameCount = frameCount + 1;

        % --- Color Transfer: Lab with style sampling from reference ---
        frameLab = rgb2lab(imresize(repmat(grayFrame,1,1,3), [256 256]));
        L = frameLab(:,:,1);
        ab = randn([size(L),2]) .* reshape(ref_std_ab,1,1,2) + reshape(ref_mean_ab,1,1,2);
        labOut = cat(3, L, ab(:,:,1), ab(:,:,2));
        rgbOut = lab2rgb(labOut); % Convert Lab to RGB
        rgbOut = im2uint8(imresize(rgbOut, size(grayFrame)));

        % --- Motion-informed tinting (for realism) ---
        if isempty(prevGray)
            motionMap = zeros(size(grayFrame));
        else
            motionMap = abs(grayFrame - prevGray);
        end
        motionBoost = min(motionMap*4,1);
        staticBoost = 1-motionBoost;
        % Warm color for static, cool for motion (softly blended)
        warmColor = cat(3, ones(size(grayFrame))*240, ones(size(grayFrame))*200, ones(size(grayFrame))*160) / 255;
        coolColor = cat(3, ones(size(grayFrame))*180, ones(size(grayFrame))*220, ones(size(grayFrame))*250) / 255;

        colorFrameF = im2double(rgbOut);
        colorFrameF = colorFrameF.*staticBoost + coolColor.*motionBoost;

        % Temporal smoothing for video realism
        if ~isempty(lastFrameF)
            colorFrameF = 0.7*colorFrameF + 0.3*lastFrameF;
        end

        colorFrame = im2uint8(colorFrameF);
        writeVideo(vidWriter, colorFrame);
        prevGray = grayFrame;
        lastFrameF = colorFrameF;

        fprintf('Processed frame %d\n', frameCount);
    end
    close(vidWriter);
    disp('✅ Video colorization complete (reference-mandatory mode).');
end



colorize_video_temporal("C:\Users\brend\OneDrive\Desktop\DIP\grayscale_vid.mp4","coloured.mp4","C:\Users\brend\OneDrive\Desktop\DIP\reference2.png");
