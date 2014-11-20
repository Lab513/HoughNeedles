function [Segments] = HoughAiguilles(BWt,BW,min_angle_diff)

Thetas = -90:0.125:89.875;


% The Hough transform: (Parameters seem optimal, change at your own risk)
[H,T,R] = hough(BWt,'RhoResolution',1,'Theta',Thetas);
P = houghpeaks(H,300,'NHoodSize',[15 15],'Threshold',15);
lines = houghlines(BW,T,R,P,'FillGap',10,'MinLength',20);


% For each [theta; rho] pair, find the longest segment:
MainSegments = 1:length(lines);
indS = 0;
while (indS < numel(MainSegments))
    linelengths = [];
    indS = indS + 1;
    % Find segments that lie on the same line, ie segments that have the
    % same rho and theta:
    SameRhoTheta = MainSegments(find([lines(MainSegments(:)).theta] == lines(MainSegments(indS)).theta & [lines(MainSegments(:)).rho] == lines(MainSegments(indS)).rho));
    % for each index of SameRhoTheta, compute the length, or euclidean distance between the two extremities of the segment:
    for indS2 = SameRhoTheta % A Q&D loop, could be replaced by a matricial function for increased efficiency.
        linelengths(end+1) = norm(lines(indS2).point1 - lines(indS2).point2);
    end
    % Keep only the longest segment, discard others:
    MainSegments = setdiff(MainSegments,SameRhoTheta(linelengths<max(linelengths)));
end
Segments = lines(MainSegments);
