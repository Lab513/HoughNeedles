function varargout = Test2(varargin)
% TEST2 MATLAB code for Test2.fig
%      TEST2, by itself, creates a new TEST2 or raises the existing
%      singleton*.
%
%      H = TEST2 returns the handle to a new TEST2 or the handle to
%      the existing singleton*.
%
%      TEST2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST2.M with the given input arguments.
%
%      TEST2('Property','Value',...) creates a new TEST2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Test2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Test2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Test2

% Last Modified by GUIDE v2.5 20-Nov-2014 17:48:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Test2_OpeningFcn, ...
                   'gui_OutputFcn',  @Test2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
                        
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else 
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Test2 is made visible.
function Test2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Test2 (see VARARGIN)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Set the default parameters for the image segmentation and initialize the GUI:
handles.th = 75;                        % The hard threshold used in the image segmentation to identify which part is needles and which is background
handles.p.display = 1;                  
handles.LastOver = 0;                   % Last segment to be passed over by the mouse pointer
handles.deleted = [];                   % Segments that were deleted by the user (includes segment fusions)
handles.selected = 1;                   % Last segment selected by the user
handles.Visibility = 1;                 % Make colored segments visible (or not)
handles.mode = '0';                     % Default mode (select mode)
handles.helptext = 'Instructions';      % Startup help text
handles.messages = ...                  % Startup information text
    'Ceci est un messageà caractère informatif';
handles.action = {};                    % List of actions taken by the user since beginning / last update of the segmentation
handles.lastpointOverplothandle = [];   % Last endpoint to be passed over by the mouse pointer (move mode)
handles.X = 1;                          % Current position of the pointer X
handles.Y = 1;                          % Current position of the pointer Y
set(handles.rules,'String',...          % List of shortcuts displayed on the GUI
    {'a - add'; 'm - move'; 'c - cut' ; 'f - fuse'; 'd - delete' ;'r - reload'; '0 - Nothing'; ;'z - undo'; 'h - hide/don''t hide segments'; 'b - black&white/normal/fluo'; ...
    't - change threshold value'; 'u - update segments to new threshold'; ;'s - save to csv' ; 'i - save image (.tif)'});
set(handles.variables,'String',...      % Startup instructions
    {'Give a background region'});


% Ask the user for a trans image filename:% Ask the user for a trans image:  
[filename,pathname,Filter] = uigetfile('./*.tif','Select the trans image to analyse');
handles.filename = fullfile(pathname,filename);
% And read it: 
handles.I = imread(handles.filename);

% Ask the user for a fluo image: 
[fluofilename,pathname,Filter] = uigetfile('./*.tif','Select the fluo image to analyse (Cancel if none)');
if fluofilename
    handles.fluofilename = fullfile(pathname,fluofilename);
    handles.F = imread(handles.fluofilename);
    handles.Fc = grs2rgb(wiener2(imadjust(handles.F),[5 5]),colormap('gray'));
    handles.FluoValues = CreateFluoValuesList(handles.Segments,setdiff(1:numel(handles.Segments),handles.deleted),handles.F);
else
    handles.fluofilename = [];
end

% Clean ou the noise out of the trans image with a wiener filter
CleanImage = imadjust(wiener2(handles.I,[5 5]));
% Ask the user to give a background (see roipoly's doc. Basically click around to give a closed surface of your background, and then right-click -> Create mask)
imshow(CleanImage)
handles.ROI = roipoly();

set(handles.variables,'String',...
    {'Processing, please wait...'});
drawnow
% Remove the image and clear the axes :
cla(handles.axes1);

% Pre-process images:
[handles.J, handles.BW, handles.BWt] = ImagePreprocessing(CleanImage, handles.ROI, handles.th, handles.p.display);
handles.Jc = grs2rgb(handles.J,colormap('gray'));

% First segmentation:
Segments = HoughAiguilles(handles.BWt,handles.BW);
Closesegments = IdentifySimilarSegments(Segments);
NewSegments = AvgSegment(Closesegments,Segments);
NewSegments = NewSegments(setdiff(1:numel(NewSegments),find(isnan([NewSegments(:).theta])))); % << Une façon dégueu de se débarasser du pb des aiguilles à 90 degrés

% Remove the segments found from the skeleton and do a second segmentation:
BWt = RemoveSegmentsFromSkeleton(NewSegments,handles.BWt);
Segments = HoughAiguilles(BWt,handles.BW);
Closesegments = IdentifySimilarSegments(Segments);
NewSegments = [NewSegments AvgSegment(Closesegments,Segments)];

% Store found segments in the handles variable
handles.Segments = NewSegments(setdiff(1:numel(NewSegments),find(isnan([NewSegments(:).theta])))); % << Une façon dégueu de se débarasser du pb des aiguilles à 90 degrés

% If there is a fluorescent image, extract the fluorescence for each
% segment and plot the fluo image
if ~isempty(handles.fluofilename)
    handles.FluoValues = CreateFluoValuesList(handles.Segments,setdiff(1:numel(handles.Segments),handles.deleted),handles.F);
    imshow(handles.Fc)
             hold on
end

% Plot the black&white image with red skeleton:
BWc = rgb2hsv(grs2rgb(imadjust(uint8(handles.BW)),colormap('gray')));
BWc(:,:,2) = double(handles.BWt);
handles.BWc = hsv2rgb(BWc);
imshow(handles.BWc);
hold on

% Plot the "RGB-ified" trans image on top of it (I transform teh image in RGB even though it is still grayscale to avoid display conflicts under Windows)
imshow(handles.Jc);

% Finally, plot the segments on it:
handles.cmap = hsv(200);
handles.cIndx = ceil(rand(numel(NewSegments),1)*200);
for k = 1:numel(handles.Segments)
    xy = [handles.Segments(k).point1; handles.Segments(k).point2];
    handles.Segments(k).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(k),:),'LineWidth',2);
end

% Create a "selection mask" from the segments data to use for segments
% selection in the different modes (see )
handles.SelectionMask = CreateSelectionMask(handles.Segments,1:numel(handles.Segments),size(handles.J));

% Save everything in the GUI's cross-functions variable "handles":
handles.hObject = hObject;
guidata(hObject,handles)
% Attribute the generic callback to MouseOver: (highlight segments when over them)
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
% Re-direct keyboard callbacks to the CkeckKeys function: 
set(hObject, 'KeyPressFcn', {@CheckKeys,handles});
% Set GUI on select mode on startup:
SelectMode(hObject,eventdata,handles);



function varargout = CheckKeys(hObject,eventdata,handles)
% This functions receives keypresses and redirects them to the appropriate
% function: 

% Load cross-function GUI data:
handles = guidata(hObject)

% Switch between different key press cases:
switch eventdata.Key
    case 'p' % For debugging only
        error('This error is here for debugging purposes only. Do not press p again. Or do it. I''m not your mom');
    case 'i'
        f=getframe(handles.axes1); [x,map]=frame2im(f); imwrite(x,[handles.filename(1:(end-4)) '_Composite.tif'],'tif');
    case 'a' % Add new segment
        AddSegmentMode(hObject,eventdata,handles);
    case 's' % Save data to csvfile
        s = handles.Segments;
        Nondeleted = setdiff(1:numel(s),handles.deleted);
        DATA = [[Nondeleted; s(Nondeleted).theta];reshape([s(Nondeleted).point1],2,numel(Nondeleted));reshape([s(Nondeleted).point2],2,numel(Nondeleted))];
        if ~isempty(handles.fluofilename)
            Fluo = CreateFluoValuesList(handles.Segments,Nondeleted,handles.F);
            DATA = [DATA; Fluo]; 
        end
        csvwrite([handles.filename(1:(end-3)) 'csv'],DATA');
        handles.messages = 'Saved';
        guidata(hObject,handles);
        UpdateVariables(hObject,eventdata);
    case 'd' % Delete segments
        DeleteSegmentsMode(hObject,eventdata,handles);
    case 'c' % Cut segments
        CutSegmentsMode(hObject,eventdata,handles);
    case 'm' % Move points of segments
        MoveSegmentsMode(hObject,eventdata,handles);
    case 'f' % Fuse segments
        FusesegmentsMode(hObject,eventdata,handles);
    case '0' % Select mode (does nothing for now)
        SelectMode(hObject,eventdata,handles);
    case 'b' % Toggle between Jc/BWc/Fc
        h = get(handles.axes1,'Children');
        if ~isempty(handles.fluofilename)
            set(handles.axes1,'Children',[h(1:end-3); h(end); h(end-2); h(end-1)]);
        else
            set(handles.axes1,'Children',[h(1:end-2); h(end); h(end-1)]);
        end
    case 'h' % Toggle Hidden/Visible segments
        handles.Visibility = ~handles.Visibility
        Nondeleted = setdiff(1:numel(handles.Segments),handles.deleted);
        for ind1 = Nondeleted
            if handles.Visibility
                set(handles.Segments(ind1).plotHandle,'Visible','On');
            else
                set(handles.Segments(ind1).plotHandle,'Visible','Off');
            end
        end
        guidata(hObject,handles);
    case 'u' % Update thresh: Redo segmentation with new value of thresh
        ChangeThreshold(hObject,eventdata,handles);
    case 't'
            thresh_Callback(hObject,eventdata,handles);
    case 'r' % Re-evaluate the selection mask
        handles.SelectionMask = CreateSelectionMask(handles.Segments,setdiff(1:numel(handles.Segments),handles.deleted),size(handles.J));
        if ~isempty(handles.fluofilename)
            handles.FluoValues = CreateFluoValuesList(handles.Segments,setdiff(1:numel(handles.Segments),handles.deleted),handles.F);
        end
        handles.messages = 'Reloaded';
        guidata(hObject,handles);
        SelectMode(hObject,eventdata,handles);
    case 'z' % undo 
        Undo(hObject,eventdata);
    
end



% The following functions don't do much, they just set the GUI in a specific
% mode and assign the proper callbacks to the mouse buttons and the
% mouseover:
function MoveSegmentsMode(hObject,eventdata,handles)

handles.mode = 'Move';
handles.helptext = 'Select the segment to modify, then click the point you want to change, and click again where you want that point to move. Double-click or press m to select another segment';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject,'WindowButtonDownFcn',{@MoveSegment1,handles});
guidata(hObject,handles);


function AddSegmentMode(hObject,eventdata,handles)

handles.mode = 'Add';
handles.helptext = 'Add a segment by clicking the two extreme points';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject,'WindowButtonDownFcn',{@Addsegment1,handles});
guidata(hObject,handles);



function CutSegmentsMode(hObject,eventdata,handles)

handles.mode = 'Cut';
handles.helptext = 'Select a segment, then click where to cut';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject,'WindowButtonDownFcn',{@Cutsegment1,handles});
guidata(hObject,handles);

function SelectMode(hObject,eventdata,handles);

handles.mode = 'Selection';
handles.helptext = 'This mode does nothing';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject,'WindowButtonDownFcn',{@Selectsegment,handles});
guidata(hObject,handles);

function DeleteSegmentsMode(hObject,eventdata,handles)

handles.mode = 'delete';
handles.helptext = 'Click on segment to delete';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject,'WindowButtonDownFcn',{@DeleteSegment,handles})
guidata(hObject,handles);

function FusesegmentsMode(hObject,eventdata,handles)

handles.mode = 'fusion';
handles.helptext = 'Click on 2 segments to fuse';
set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
guidata(hObject,handles);
set(hObject,'WindowButtonDownFcn',{@Fuse2segments1,handles});


% First state of the MoveSegment mode: Once the user clicked a segment, it is
% stored in handles.selected. Then the proper callbacks are applied (goes to state 2 of the mode)
function MoveSegment1(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;


if X && Y 
    handles.X = X;
    handles.Y = Y;
    if handles.SelectionMask(Y,X)
        handles.selected = handles.SelectionMask(Y,X);
        guidata(hObject,handles);
        UpdateVariables(hObject,eventdata);
        set(hObject,'windowbuttonmotionfcn',{@MouseOverCallbackPoints,handles});
        set(hObject,'WindowButtonDownFcn',{@MoveSegment2,handles});
    end
end

% Second state of the MoveSegment mode: Once the user clicked a point, it is
% stored in "point". Then the proper callbacks are applied (goes to state 3 of the mode)
function MoveSegment2(hObject,eventdata,handles)
handles = guidata(hObject);
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

if X && Y
    handles.X = X;
    handles.Y = Y;
    guidata(hObject,handles);
    UpdateVariables(hObject,eventdata);
    point = nearestpoint(handles.Segments(handles.selected),X,Y);
    guidata(hObject,handles);
    set(hObject,'windowbuttonmotionfcn','');
    set(hObject,'WindowButtonDownFcn',{@MoveSegment3,handles,point});
end

% Third state of the MoveSegment mode: Once the user clicked where to move the point, it is
% moved and the segment's data is updated. Then the proper callbacks are applied (goes back to state 2 of the mode)
function MoveSegment3(hObject,eventdata,handles,point)
handles = guidata(hObject)

if strcmp( get(gcf,'selectionType') , 'normal')
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

if X && Y
    handles.X = X;
    handles.Y = Y;    
    delete(handles.lastpointOverplothandle);
    handles.lastpointOverplothandle = [];
    if point == 1
        oP = handles.Segments(handles.selected).point1;
        oT = handles.Segments(handles.selected).theta;
        handles.Segments(handles.selected).point1 = [X,Y];
    else 
        oP = handles.Segments(handles.selected).point2;
        handles.Segments(handles.selected).point2 = [X,Y];
        oT = handles.Segments(handles.selected).theta;
    end
    if (handles.Segments(handles.selected).point1(1) - handles.Segments(handles.selected).point2(1)) == 0
        handles.Segments(handles.selected).point1(1) = handles.Segments(handles.selected).point1(1) + 1;
    end
    handles.Segments(handles.selected).theta = atand((handles.Segments(handles.selected).point1(1) - handles.Segments(handles.selected).point2(1))/(handles.Segments(handles.selected).point1(2) - handles.Segments(handles.selected).point2(2)));
    
    xy = [handles.Segments(handles.selected).point1; handles.Segments(handles.selected).point2];
    delete(handles.Segments(handles.selected).plotHandle);
    
    
    handles.Segments(handles.selected).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(handles.selected),:),'LineWidth',2);
    handles.action{end+1} = struct('name', 'move','Segment',handles.selected,'point',point,'oP',oP,'oT',oT); % To be modified!
    guidata(hObject,handles);
    set(hObject,'windowbuttonmotionfcn',{@MouseOverCallbackPoints,handles});
    set(hObject,'WindowButtonDownFcn',{@MoveSegment2,handles});
end


elseif strcmp( get(gcf,'selectionType') , 'open')
    set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles});
    delete(handles.lastpointOverplothandle);
    handles.lastpointOverplothandle = [];
    guidata(hObject,handles);
    set(hObject,'WindowButtonDownFcn',{@MoveSegment1,handles});
end
    


% First state of the Addsegment mode: Once the user clicked the first point of the segment,
% the coordinates are stored in handles.X & handles.Y .The proper callbacks are applied (goes to state 2 of the mode)
function Addsegment1(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;


if X && Y
    handles.X = X;
    handles.Y = Y;
    set(hObject,'WindowButtonDownFcn',{@Addsegment2,handles,X,Y});
end

% Second state of the Addsegment mode: Once the user clicked the second point of the segment,
% tjhe segment is created .The proper callbacks are applied (goes back to state 1 of the mode)
function Addsegment2(hObject,eventdata,handles,fX,fY)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

handles = guidata(hObject);

if X && Y
    handles.X = X;
    handles.Y = Y;
    
    handles.Segments(end+1).point1 = [fX,fY];
    handles.Segments(end).point2 = [X,Y];
    if fX-X ~= 0
        handles.Segments(end).theta = atand((fY-Y)/(fX-X));
    else
        handles.Segments(end).point2 = [X+1,Y];
        handles.Segments(end).theta = atand((fY-Y)/(fX-X-1));
    end
    handles.cIndx(end+1) = ceil(rand()*200);
    xy = [fX fY; X Y];
    handles.Segments(end).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(end),:),'LineWidth',2);
    handles.action{end+1} = struct('name', 'add','Segment',numel(handles.Segments));
    set(hObject,'WindowButtonDownFcn',{@Addsegment1,handles});
    guidata(handles.hObject,handles);
    UpdateVariables(hObject,eventdata);
end

% Second state of the Cutsegment mode: Once the user clicked where to cut the segment,
% the segment is cut and the new segments are updated in handles.segments .The proper callbacks are applied (goes back to state 1 of the mode)
function Cutsegment2(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

if X && Y 
    handles.X = X;
    handles.Y = Y;
    q = project_point_to_line_segment(handles.Segments(handles.selected).point1,handles.Segments(handles.selected).point2,[X,Y]);
    Segment1 = handles.Segments(handles.selected);
    Segment1.point2 = q;
    Segment2 = handles.Segments(handles.selected);
    Segment2.point1 = q;
    handles.Segments(handles.selected) = Segment1;
    xy = [Segment1.point1; Segment1.point2];
    set(handles.Segments(handles.selected).plotHandle,'Visible','Off')
    handles.Segments(handles.selected).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(handles.selected),:),'LineWidth',2);
    handles.Segments(end+1) = Segment2;
    handles.cIndx(end+1) = ceil(rand()*200);
    xy = [Segment2.point1; Segment2.point2];
    handles.Segments(end).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(end),:),'LineWidth',2);
    handles.messages = ['Cut ' num2str(handles.selected) ' -> ' num2str(handles.selected) ' & ' num2str(numel(handles.Segments))];
    handles.action{end+1} = struct('name', 'cut','first',handles.selected,'second',numel(handles.Segments));
    guidata(handles.hObject,handles);
    UpdateVariables(hObject,eventdata);
    CutSegmentsMode(hObject,eventdata,handles)
end


% First state of the Cutsegment mode: Once the user clicked which segmetn to cut,
% it is stored in handles.selected.The proper callbacks are applied (goes to state 2 of the mode)
function Cutsegment1(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

handles = guidata(hObject);

if X && Y 
    handles.X = X;
    handles.Y = Y;
    if handles.SelectionMask(Y,X)
        handles.selected = handles.SelectionMask(Y,X);
        guidata(hObject,handles);
        UpdateVariables(hObject,eventdata);
        set(hObject,'WindowButtonDownFcn',{@Cutsegment2,handles});
    end
end

% First state of the Fusesegments mode: Once the user clicked the first segment to fuse,
% it is stored in handles.selected.The proper callbacks are applied (goes to state 2 of the mode)
function Fuse2segments1(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

handles = guidata(hObject);

if X && Y 
    handles.X = X;
    handles.Y = Y;
    if handles.SelectionMask(Y,X)
        handles.selected = handles.SelectionMask(Y,X);
    end
    guidata(hObject,handles);
    UpdateVariables(hObject,eventdata);    
    set(hObject,'WindowButtonDownFcn',{@Fuse2segments2,handles});
end


% Second state of the Fusesegments mode: Once the user clicked the second segment to fuse,
% the two segments are fused and handles.segments is updated .The proper callbacks are applied (goes back to state 1 of the mode)
function Fuse2segments2(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

handles = guidata(hObject);

if X && Y
    handles.X = X;
    handles.Y = Y;
    if handles.SelectionMask(Y,X)
        Fusion = handles.SelectionMask(Y,X);
        handles.action{end+1} = struct('name','fuse','del',Fusion,'first',handles.selected,'Seg',handles.Segments(handles.selected))
        Segtmp = AvgSegment({[handles.selected,Fusion]},handles.Segments);
        xy = [Segtmp.point1; Segtmp.point2];
        Segtmp.plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(handles.selected),:),'LineWidth',2);
        set(handles.Segments(handles.selected).plotHandle,'Visible','off');
        handles.Segments(handles.selected) = Segtmp;
        set(handles.Segments(Fusion).plotHandle,'Visible','off');
        handles.deleted = [handles.deleted Fusion];
        handles.messages = ['Fused ' num2str(handles.selected) ' & ' num2str(Fusion) ' -> ' num2str(numel(handles.Segments))];
    else
        handles.messages = ['T''as cliqué à côté'];
    end
    
    guidata(handles.hObject,handles);
    UpdateVariables(hObject,eventdata);
    set(hObject,'WindowButtonDownFcn',{@Fuse2segments1,handles});
end


% First (and only) state of the deletesegment mode: Once the user clicked a segment segment to delete,
% it is deleted and handles.segemtns is updated. The callbacks remain
% unchanged
function DeleteSegment(hObject,eventdata,handles)
C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

handles = guidata(hObject);

if X && Y 
handles.X = X;
handles.Y = Y;
handles.selected = handles.SelectionMask(Y,X);
if handles.selected
    handles.deleted = [handles.deleted handles.selected];
    handles2hide = [handles.Segments(handles.selected).plotHandle; cell2mat(get(handles.Segments(handles.selected).plotHandle,'Children'))];
    set(handles2hide,'Visible','off')
    handles.messages = ['Deleted ' num2str(handles.selected)];
    handles.action{end+1} = struct('name', 'delete','first',handles.selected);
end
handles.deleted
guidata(hObject,handles);
UpdateVariables(hObject,eventdata);
end


% First (and only) state of the selectsegment mode: Once the user clicked a segment, some 
% information is displayed on the side. The callbacks remain
% unchanged
function Selectsegment(hObject,eventdata,handles)

C = get (handles.axes1, 'CurrentPoint');
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 0;
Y(Y>1040) = 0;
X(X<1) = 0; 
Y(Y<1) = 0;

if X && Y
handles.X = X;
handles.Y = Y;
handles.selected = handles.SelectionMask(Y,X)
guidata(hObject,handles);
UpdateVariables(hObject,eventdata);
end


% The Undo function cancels past actions
function Undo(hObject,eventdata)
handles = guidata(hObject)

k = numel(handles.action)
while  k > 0 && isempty(handles.action{k})
    k = k-1;
end
if k > 0
    switch handles.action{k}.name
        case 'delete'
            handles.deleted = setdiff(handles.deleted,handles.action{k}.first);
            set(handles.Segments(handles.action{k}.first).plotHandle,'Visible','On');
        case 'cut'
            
            handles.Segments(handles.action{k}.first).point2 = handles.Segments(handles.action{k}.second).point2;
            set(handles.Segments(handles.action{k}.first).plotHandle,'Visible','Off');
            xy = [handles.Segments(handles.action{k}.first).point1; handles.Segments(handles.action{k}.first).point2];
            handles.Segments(handles.action{k}.first).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(handles.action{k}.first),:),'LineWidth',2);
            
            handles.deleted = [handles.deleted handles.action{k}.second];
            set(handles.Segments(handles.action{k}.second).plotHandle,'Visible','Off')
            
        case 'fuse'
            
            handles.deleted = setdiff(handles.deleted,handles.action{k}.del);
            set(handles.Segments(handles.action{k}.del).plotHandle,'Visible','On');
            
            set(handles.Segments(handles.action{k}.first).plotHandle,'Visible','Off');
            handles.Segments(handles.action{k}.first) = handles.action{k}.Seg;
            set(handles.Segments(handles.action{k}.first).plotHandle,'Visible','On');
        case 'add'
            handles.deleted = [handles.deleted, handles.action{k}.Segment];
            set(handles.Segments(handles.action{k}.Segment).plotHandle,'Visible','Off');
        case 'move'
            switch handles.action{k}.point
                case 1
                    handles.Segments(handles.action{k}.Segment).point1 = handles.action{k}.oP;
                case 2
                    handles.Segments(handles.action{k}.Segment).point2 = handles.action{k}.oP;
            end
            handles.Segments(handles.action{k}.Segment).theta = handles.action{k}.oT;
            set(handles.Segments(handles.action{k}.Segment).plotHandle,'Visible','Off');
            xy = [handles.Segments(handles.action{k}.Segment).point1; handles.Segments(handles.action{k}.Segment).point2];
            handles.Segments(handles.action{k}.Segment).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(handles.action{k}.Segment),:),'LineWidth',2);
            
    end
    handles.action{k} = [];
end
guidata(hObject,handles)



% The MouseoverCallback function highlights overed segment
function MouseOverCallback(hObject,eventdata,handles)

C = get (handles.axes1, 'CurrentPoint');



X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 1392;
Y(Y>1040) = 1040;
X(X<1) = 1; 
Y(Y<1) = 1;



data = guidata(hObject);
data.X = X;
data.Y = Y;

LO= data.LastOver;
if handles.SelectionMask(Y,X)
    set(handles.Segments(handles.SelectionMask(Y,X)).plotHandle, 'LineWidth', 3.5)
    data.LastOver = handles.SelectionMask(Y,X);
end
if  LO && LO ~= handles.SelectionMask(Y,X)
        set(handles.Segments(LO).plotHandle, 'LineWidth', 2)
        data.LastOver = handles.SelectionMask(Y,X);
end
guidata(hObject,data);
handles = data;
UpdateVariables(hObject,eventdata);

% The MouseoverCallbackPoints function highlights overed points (MoveSegment mode)
function MouseOverCallbackPoints(hObject,eventdata,handles)

handles = guidata(hObject)

C = get (handles.axes1, 'CurrentPoint');


 
X = ceil(C(1,1));
Y = ceil(C(1,2));
X(X>1392) = 1392;
Y(Y>1040) = 1040;  
X(X<1) = 1; 
Y(Y<1) = 1;

LPH = handles.lastpointOverplothandle;
if ~isempty(LPH)
    delete(LPH);
    handles.lastpointOverplothandle = [];
end
point = nearestpoint(handles.Segments(handles.selected),X,Y);
if point == 1
    xy = handles.Segments(handles.selected).point1;
    handles.lastpointOverplothandle = plot(xy(1),xy(2),'o','LineWidth',3.5,'Color',handles.cmap(handles.cIndx(handles.selected),:));
else
    xy = handles.Segments(handles.selected).point2;
    handles.lastpointOverplothandle = plot(xy(1),xy(2),'o','LineWidth',3.5,'Color',handles.cmap(handles.cIndx(handles.selected),:));
end
guidata(hObject,handles)



% Change the variables text box:
function UpdateVariables(hObject,eventdata)
handles = guidata(hObject); 
Stringlist = {['MODE: ' handles.mode]; ['X = ' num2str(handles.X,'%03.f') '; Y = ' num2str(handles.Y,'%03.f') ];... 
    [' Over segment #' num2str(handles.LastOver)];
    ['Selected segment #' num2str(handles.selected)];
    ['# of segments: ' num2str(numel(handles.Segments)-numel(handles.deleted))];'';'';
    handles.helptext;'';'';
    handles.messages;'';'';
    }; 
set(handles.variables,'String',Stringlist)



% This function allows to change threshold value. The whole segmentation
% isn't run again, but you can see the change in the B&W image
function thresh_Callback(hObject, eventdata, handles)
% hObject    handle to thresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of thresh as text
%        str2double(get(hObject,'String')) returns contents of thresh as a double

 val = inputdlg('New threshold: ');
 if ~isempty(val)
    val = val{1};
 end
 if ~isempty(val) && ~sum(~isstrprop(val, 'digit')) 
     val = str2num(val);
     if val >= 0 && val < 255
         handles.th = val;

         [handles.J, handles.BW, handles.BWt] = ImagePreprocessing(handles.J,handles.ROI, handles.th, handles.p.display);
         handles.Jc = grs2rgb(handles.J,colormap('gray'));
         BWc = rgb2hsv(grs2rgb(imadjust(uint8(handles.BW)),colormap('gray')));
         BWc(:,:,2) = double(handles.BWt);
         handles.BWc = hsv2rgb(BWc);
         
         h = get(handles.axes1,'Children');
         delete(h(end));
         delete(h(end-1));
         if ~isempty(handles.fluofilename)
            delete(h(end-2));
         end
         imshow(handles.Jc);
         imshow(handles.BWc);
         if ~isempty(handles.fluofilename);
             imshow(handles.Fc);
             h = get(handles.axes1,'Children');
             set(handles.axes1,'Children',[h(4:end); h(2); h(3); h(1)]);
         else
             h = get(handles.axes1,'Children');
             set(handles.axes1,'Children',[h(3:end); h(1); h(2)]);
         end
         
         handles.messages = ['New threshold: ' num2str(handles.th)];
     else
         handles.messages = 'Threshold must be between 0 and 256';
     end
 else
     handles.messages = '!!!Enter a number only for threshold!!!';
 end

guidata(hObject,handles);
UpdateVariables(hObject,eventdata);


% Once you have changed the threshold and it seems good for you to run a
% new segmentation, this function does just it: Re-do teh segmentation it
% did at the very beginning:
function ChangeThreshold(hObject,eventdata,handles)

handles = guidata(hObject);

handles.deleted = [];
handles.selected = 0;
handles.Visibility = 1;
handles.helptext = 'Instructions';
handles.messages = 'Ceci est un message à caractère informatif';


% Clear axes
cla(handles.axes1)

% First segmentation:
Segments = HoughAiguilles(handles.BWt,handles.BW);
Closesegments = IdentifySimilarSegments(Segments);
NewSegments = AvgSegment(Closesegments,Segments);
NewSegments = NewSegments(setdiff(1:numel(NewSegments),find(isnan([NewSegments(:).theta])))); % << Une façon dégueu de se débarasser du pb des aiguilles à 90 degrés

% Remove the segments found from the skeleton and do a second segmentation:
BWt = RemoveSegmentsFromSkeleton(NewSegments,handles.BWt);
Segments = HoughAiguilles(BWt,handles.BW);
Closesegments = IdentifySimilarSegments(Segments);
NewSegments = [NewSegments AvgSegment(Closesegments,Segments)];
handles.Segments = NewSegments(setdiff(1:numel(NewSegments),find(isnan([NewSegments(:).theta])))); % << Une façon dégueu de se débarasser du pb des aiguilles à 90 degrés

handles.cmap = hsv(200);
handles.cIndx = ceil(rand(numel(NewSegments),1)*200);

% Plot anew
if ~isempty(handles.fluofilename)
    imshow(handles.Fc);
end
BWc = rgb2hsv(grs2rgb(imadjust(uint8(handles.BW)),colormap('gray')));
BWc(:,:,2) = double(handles.BWt);
handles.BWc = hsv2rgb(BWc);
imshow(handles.BWc);
hold on
imshow(handles.Jc)
hold on
for k = 1:numel(handles.Segments)
    xy = [handles.Segments(k).point1; handles.Segments(k).point2];
    handles.Segments(k).plotHandle = plot(xy(:,1),xy(:,2),'Color',handles.cmap(handles.cIndx(k),:),'LineWidth',2);
end


if ~isempty(handles.fluofilename)
    handles.FluoValues = CreateFluoValuesList(handles.Segments,setdiff(1:numel(handles.Segments),handles.deleted),handles.F);
end

handles.SelectionMask = CreateSelectionMask(handles.Segments,1:numel(handles.Segments),size(handles.J));

guidata(hObject,handles);
UpdateVariables(hObject,eventdata);

set(hObject,'windowbuttonmotionfcn',{@MouseOverCallback,handles}); 
set(hObject, 'KeyPressFcn', {@CheckKeys,handles});
SelectMode(hObject,eventdata,handles);


% UTILITIES:

% --- Outputs from this function are returned to the command line.
function varargout = Test2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles = guidata(hObject);
s = handles.Segments;
Nondeleted = setdiff(1:numel(s),handles.deleted);
DATA = [[Nondeleted; s(Nondeleted).theta]; ... 
    reshape([s(Nondeleted).point1],2,numel(Nondeleted)); ...
    reshape([s(Nondeleted).point2],2,numel(Nondeleted))];
handles.output = DATA;
varargout{1} = handles.output;


% The T-shaped button just cancels the zoom and pan mode and allows one to
% resume to the normal modes
function uipushtool2_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
zoom off
pan off



% The following function shamelessly taken from Alec Jacobson's blog:
% http://www.alecjacobson.com/weblog/?p=1486
function [q] = project_point_to_line_segment(A,B,p)
  % returns q the closest point to p on the line segment from A to B 

  % vector from A to B
  AB = (B-A);
  % squared distance from A to B
  AB_squared = dot(AB,AB);
  if(AB_squared == 0)
    % A and B are the same point
    q = A;
  else
    % vector from A to p
    Ap = (p-A);
    % from http://stackoverflow.com/questions/849211/
    % Consider the line extending the segment, parameterized as A + t (B - A)
    % We find projection of point p onto the line. 
    % It falls where t = [(p-A) . (B-A)] / |B-A|^2
    t = dot(Ap,AB)/AB_squared;
    if (t < 0.0) 
      % "Before" A on the line, just return A
      q = A;
    else if (t > 1.0) 
      % "After" B on the line, just return B
      q = B;
    else
      % projection lines "inbetween" A and B on the line
      q = A + t * AB;
    end
  end
end




% Finds the nearest of two points to another point.
function point = nearestpoint(segment,X,Y)

d = dist([segment.point1',segment.point2',[X;Y]]);
d1 = d(1,3);
d2 = d(2,3);
[~, point] = min([d1,d2]);
