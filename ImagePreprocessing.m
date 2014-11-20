function [CleanImage, BW_Mask, Skeleton] = ImagePreprocessing(CleanImage, ROI, thresh, display)
% This function takes an image I as an input, provides a cleaner image of
% that image and extracts the objects mask and skeleton.


CloseDisk = strel('Disk',2);

a = mean(CleanImage(ROI));

% Identify regions w/ object and background region
K = abs(double(CleanImage) - a); % Make the average background value the level 0 of intensity. Anything below that (esp. the needles) will have a value > 0
M = imgradient(K); % Get the 2D image gradient
M = (M-min(M(:)))./(max(M(:))-min(M(:))); % Scale M values between 0 & 1
N = im2bw(M,1.1*(max(M(ROI))/max(M(:)))); % Identify areas with gradient values higher than background and 
O = imopen(imclose(N,CloseDisk),strel('Disk',4)); % Clean the image a bit

% Use user-given threshold 'thresh' for finer differenciation of background
% vs. objects
CleanImage3 = double(CleanImage);
CleanImage3b = CleanImage3;
CleanImage3 = imcomplement(CleanImage3);
CleanImage3(O==0) = 0;
CleanImage3(CleanImage3b > thresh ) = 0;
BW_Mask = ones(size(CleanImage3));
BW_Mask(CleanImage3 == 0) = 0;
BWo = imopen(BW_Mask,strel('Disk',3));
BW_Mask = imreconstruct(BWo,BW_Mask);
BW_Mask = imclose(BW_Mask,strel('Disk',5));   % Here we've got the clean B/W mask of our objects
Skeleton = bwmorph(BW_Mask,'thin',Inf);       % Get skeleton of the objects
% 
% if display
%     figure(2)
%     BWc = rgb2hsv(grs2rgb(imadjust(uint8(BW_Mask)),colormap('gray')));
%     BWc(:,:,2) = double(Skeleton);
%     BWc = hsv2rgb(BWc);
%     imshow(BWc);
%     title('BW_mask & Skeleton')
% end
    