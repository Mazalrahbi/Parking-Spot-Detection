clc
clear all
close all
desiredFile1='Parking Lot with Cars'; % Name of image with cars in the parking
desiredFile2='Parking Lot without Cars'; % Name of image without cars in the parking
desiredFile3='Parking Lot Mask'; % Name of image of parking mask
message='Do you want to start analysis in current folder?'; % showing message 
if isequal(questdlg(message,'Message','Yes','Change Folder','Yes'),'Change Folder') % choosing option
    cd(uigetdir(pwd)); % changing folder
end
fnd1=false; fnd2=false; fnd3=false; % to check if all three files have been found
while(true)
    images=dir(pwd);
    for i=1:length(images)
        [~,name,~]=fileparts(images(i).name);
        if isequal(name,desiredFile1)
            filledParking=imread(images(i).name);
            fnd1=true;
        end
        if isequal(name,desiredFile2)
            emptyParking=imread(images(i).name);
            fnd2=true;
        end
        if isequal(name,desiredFile3)
            parkingMask=imread(images(i).name);
            fnd3=true;
        end
        if fnd1&&fnd2&&fnd3
            break;
        end
    end
    if ~(fnd1&&fnd2&&fnd3)
        errorMessage = sprintf('Error: one of desired images does not exist,Please Select correct folder.');
        ch=questdlg(errorMessage,'Message','Select Folder','Cancel','Cancel');
        if isequal(ch,'Select Folder')
            cd(uigetdir);
        else
            return;
        end
    else
        break;
    end
end
fig1=figure();
fig1.WindowState = 'maximized';
subplot(2,3,1)
imshow(filledParking);
axis off;
title('Parking filled with cars');
subplot(2,3,2)
imshow(emptyParking);
axis off;
title('Empty Parking');
subplot(2,3,3)
bwMask=min(parkingMask,[],3)==255
bwMask=imfill(bwMask, 'holes');
bwMask=imopen(bwMask,strel('rectangle',[2,4]));
bwMask=bwconvhull(bwMask, 'objects');
props=regionprops(bwMask,rgb2gray(parkingMask),'BoundingBox','MeanIntensity','Centroid');
imshow(bwMask);
m=1;
for i=1:length(props)
    if(props(i).MeanIntensity>0.1)
        rectangle('Position',props(i).BoundingBox,'EdgeColor','r','LineWidth',2 );
        allLocations{m}=props(i).BoundingBox;
        allCentroids{m}=props(i).Centroid;
        m=m+1;
    end
end
axis off;
title('Parking Mask');
subplot(2,3,4)
diffImage=imabsdiff(filledParking,emptyParking);
imshow(diffImage);
axis off;
title('Difference Image');
subplot(2,3,5)
diffImage=rgb2gray(diffImage);
diffImage(~bwMask)=0;
imshow(diffImage);
axis off;
title('Gray Scale Difference Image');
threshold=graythresh(diffImage)*100;
parkedCars=diffImage>threshold;
parkedCars=imfill(parkedCars, 'holes');
parkedCars=imerode(parkedCars,strel('rectangle',[2,4]));
parkedCars=bwconvhull(parkedCars, 'objects');
subplot(2,3,6);
imshow(parkedCars);
axis off;
title(sprintf('Parked Cars Binary Image with Threshold = %.1f', threshold));
iprops=regionprops(bwMask,parkedCars,'BoundingBox','MeanIntensity','Centroid');
m=1;
for i=1:length(iprops)
    if(iprops(i).MeanIntensity>0.1)
        rectangle('Position',iprops(i).BoundingBox,'EdgeColor','y','LineWidth',2 );
        takenLocations{m}=iprops(i).BoundingBox;
        takenCentroids{m}=iprops(i).Centroid;
        m=m+1;
    end
end
fig1.Name = 'Car Parking Analysis';
fig2=figure();
imshow(filledParking)
fig2.WindowState = 'maximized';
for i=1:length(allLocations)
    taken=false;
    box1=allLocations{i};
    r1=rectangle('Position',box1,'EdgeColor','r','LineWidth',2 );
    for j=1:length(takenLocations)
        box2=takenLocations{j};
        r2=rectangle('Position',box2,'EdgeColor','y','LineWidth',2 );
        ratio=bboxOverlapRatio(box1,box2);
        if ratio>0.1
            cent=allCentroids{i};
            hold on
            plot(cent(1),cent(2),'-x','Color','r','markerSize',25,'lineWidth',8);
            hold off
            taken=true;
            break;
        end
    end
    if ~taken
        cent=allCentroids{i};
        hold on
        plot(cent(1),cent(2),'-o','Color','g','markerSize',25,'lineWidth',8);
        hold off
    end
end
rect=findall(gcf,'Type','Rectangle');
delete(rect);
fig2.Name = 'Results';
title('Marked Spaces.  Green O = Available.  Red X = Taken.');