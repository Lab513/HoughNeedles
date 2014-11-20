function [ValuesList] = CreateFluoValuesList(Segments,list,F)

s = size(F);
FluoValues = zeros(size(list));
rectW = 1;
ind2 = 0;
for ind1 = list
    ind2 = ind2 + 1;
    x = [rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point1(1), -rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point1(1), -rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point2(1), rectW*cosd(Segments(ind1).theta+90)+ Segments(ind1).point2(1)];
    y = [rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point1(2), -rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point1(2), -rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point2(2), rectW*sind(Segments(ind1).theta+90)+ Segments(ind1).point2(2)];
    BWp = poly2mask(x,y,s(1),s(2));
    ValuesList(ind2) = mean(F(find(BWp)));
end