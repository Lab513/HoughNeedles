function [Skeleton] = RemoveSegmentsFromSkeleton(Segments,Skeleton)

s = size(Skeleton);
rectW = 3;
for ind1 = 1:numel(Segments)
    x = [rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point1(1), -rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point1(1), -rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point2(1), rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point2(1)];
    y = [rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point1(2), -rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point1(2), -rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point2(2), rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point2(2)];
    BWp = poly2mask(x,y,s(1),s(2));
    Skeleton(BWp) = 0;
end
