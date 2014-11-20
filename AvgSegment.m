function [NewSegments] = AvgSegment(Closesegmentslist,Segments)
% This function computes the average segment out of each element of the
% list of segments described in Closesegmentslist


Thetapol = [];
NewSegments = [];
for kc = 1:numel(Closesegmentslist)
    
    point1s = reshape([Segments(Closesegmentslist{kc}(:)).point1],2,numel(Closesegmentslist{kc}));
    point2s = reshape([Segments(Closesegmentslist{kc}(:)).point2],2,numel(Closesegmentslist{kc}));
    Ys = [point1s(2,:) point2s(2,:)];
    Xs = [point1s(1,:) point2s(1,:)];
    Xb = mean(Xs);
    Yb = mean(Ys);
    b1 = sum((Xs-Xb).*(Ys-Yb))/sum((Xs-Xb).^2);
    b0 = Yb - b1*Xb;
    
    NewSegments(kc).theta = atand(b1);
    NewSegments(kc).rho = b0;

    Proj = [];

    for k = Closesegmentslist{kc}
        [P1TH,P1RH] = cart2pol(Segments(k).point1(1),Segments(k).point1(2));
        [P2TH,P2RH] = cart2pol(Segments(k).point2(1),Segments(k).point2(2));
        Proj(end+1)  = P1RH*cosd(radtodeg(P1TH)-NewSegments(kc).theta);
        Proj(end+1)  = P2RH*cosd(radtodeg(P2TH)-NewSegments(kc).theta);
        Thetapol = [Thetapol P1TH P2TH];
    end

        [m2, i2] = max(Proj);

        [m1, i1] = min(Proj);


    if abs(NewSegments(kc).theta) < 45
        if mod(i1,2)
            i1 = ceil(i1/2);
            NewSegments(kc).point1 = [Segments(Closesegmentslist{kc}(i1)).point1(1) tand(NewSegments(kc).theta)*Segments(Closesegmentslist{kc}(i1)).point1(1) + NewSegments(kc).rho];
        else
            i1 = ceil(i1/2);
            NewSegments(kc).point1 = [Segments(Closesegmentslist{kc}(i1)).point2(1) tand(NewSegments(kc).theta)*Segments(Closesegmentslist{kc}(i1)).point2(1) + NewSegments(kc).rho];
        end
        if mod(i2,2)
            i2 = ceil(i2/2);
            NewSegments(kc).point2 = [Segments(Closesegmentslist{kc}(i2)).point1(1) tand(NewSegments(kc).theta)*Segments(Closesegmentslist{kc}(i2)).point1(1) + NewSegments(kc).rho];
        else
            i2 = ceil(i2/2);
            NewSegments(kc).point2 = [Segments(Closesegmentslist{kc}(i2)).point2(1) tand(NewSegments(kc).theta)*Segments(Closesegmentslist{kc}(i2)).point2(1) + NewSegments(kc).rho];
        end
    else
        if mod(i1,2)
            i1 = ceil(i1/2);
            NewSegments(kc).point1 = [(Segments(Closesegmentslist{kc}(i1)).point1(2) - NewSegments(kc).rho)/tand(NewSegments(kc).theta) Segments(Closesegmentslist{kc}(i1)).point1(2)];
        else
            i1 = ceil(i1/2);
            NewSegments(kc).point1 = [(Segments(Closesegmentslist{kc}(i1)).point2(2) - NewSegments(kc).rho)/tand(NewSegments(kc).theta) Segments(Closesegmentslist{kc}(i1)).point2(2)];;
        end
        if mod(i2,2)
            i2 = ceil(i2/2);
            NewSegments(kc).point2 = [(Segments(Closesegmentslist{kc}(i2)).point1(2) - NewSegments(kc).rho)/tand(NewSegments(kc).theta) Segments(Closesegmentslist{kc}(i2)).point1(2)];
        else
            i2 = ceil(i2/2);
            NewSegments(kc).point2 = [(Segments(Closesegmentslist{kc}(i2)).point2(2) - NewSegments(kc).rho)/tand(NewSegments(kc).theta) Segments(Closesegmentslist{kc}(i2)).point2(2)];
        end
    end
end

