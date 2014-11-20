function Closesegmentslist = IdentifySimilarSegments(AllSegments)
% Per needle, the Hough transform identifies several segments. Here we
% group them together into a cell of lists: Closesegmentslist
% Identify suspiciously close segments:
min_angle_diff = 7.5;

IdpdtSegmentslist = 1:numel(AllSegments);
indC = 0;
while (indC < numel(IdpdtSegmentslist))
    indC = indC + 1;
    Closesegmentslist{indC} = [IdpdtSegmentslist(indC)];
    Distcs{indC} = 0;
    for indC2 = (indC+1):numel(IdpdtSegmentslist)
        ThetaDiff = abs(AllSegments(IdpdtSegmentslist(indC)).theta - AllSegments(IdpdtSegmentslist(indC2)).theta);
       if (ThetaDiff < min_angle_diff || ThetaDiff > (180-min_angle_diff)) && DistBetween2Segment(AllSegments(IdpdtSegmentslist(indC)).point1,AllSegments(IdpdtSegmentslist(indC)).point2,AllSegments(IdpdtSegmentslist(indC2)).point1,AllSegments(IdpdtSegmentslist(indC2)).point2) < 5
        Closesegmentslist{indC} = [Closesegmentslist{indC} IdpdtSegmentslist(indC2)];
       end
    end
    if numel(Closesegmentslist{indC}) > 1
       IdpdtSegmentslist = setdiff(IdpdtSegmentslist,Closesegmentslist{indC}(2:end));
    end
end