function imageanalysisui(varargin)
%%%accepts an input of a bfopen file and opens a gui to quantify various
%%%aspects

if isempty(varargin) == 1
    disp('Please load a movie!')
    nd_file = bfopen;
else
    nd_file = varargin{1};
end
close all
figure
screendim=get(0,'screensize');
figsize=[screendim(3)*0.8 screendim(4)*0.8];
screenpos=[screendim(3)*0.1 screendim(4)*0.1];
set(gcf,'Position',[screenpos figsize])


%%%sets position and size of figure adjusted to monitor settings

pts=0;
pix_size=0.105;
r_scaler = 1;
g_scaler = 1;
b_scaler = 1;
cyan = [0.152941176470588 0.658823529411765 0.878431372549020];
orange =  [0.956862745098039,0.498039215686275,0.215686274509804];

%Set default values for a number of properties to be plugged in functions
%later on in the code, including the tracking struct pts, the pixel size,
%the brightness scaling factor, and the colors of circles to draw



metadata=nd_file{1,4};
xdim = metadata.getPixelsSizeX(0).getValue(); % image width, pixels
ydim = metadata.getPixelsSizeY(0).getValue(); % image height, pixels
if length(varargin)<2
    num_z = metadata.getPixelsSizeZ(0).getValue(); % number of Z slices
    num_c = metadata.getPixelsSizeC(0).getValue(); % number of wavelengths
    num_t = metadata.getPixelsSizeT(0).getValue(); % number of timepoints
    num_p = metadata.getImageCount(); %number of stage positions
else
    dims = varargin{2};
    
    num_t = dims(1);
    
    num_z = dims(2);
    
    num_p = dims(3);
    
    num_c = dims(4);
    
    %changes the dimensions according to your inputs
end

check=questdlg('Do you have a color with a different number of z steps?','Unequal Colors?','Yes','No','No');

if strcmp(check,'Yes') == 1   
    pos_ind = (1: 2 : num_p);
    num_p = num_p / 2;
else
    pos_ind = (1 : num_p);
end


timepoints = gettimestepOME(metadata, num_z, num_p, num_c , num_t); %list of timepoints


%%%Pulls metadata from OME format. useful because it does not change
%%%between file formats and acquisition programs




dimensions=[num_c num_z num_p num_t];

pixeldim=[ydim xdim];

alldim=[pixeldim dimensions];

megastack=zeros(alldim);

if num_c > 3
    colors= [1 2 3 4];
    drop=input('Too many colors! Please chose which channel to drop (1-4) ');
    
    drop = str2double(drop);
    disp_colors = colors;
    disp_colors(ismember(colors, drop)) = [];
end

for i=pos_ind
    t_ind=0;
    for x=1:num_t
        planes=0;
        if num_c < 4
            disp_colors = 1:num_c;
            for j=1:num_c
                for q=1:num_z
                    megastack(:,:,j,q,i,x)=nd_file{i,1}{q+(j-1)*num_z + t_ind, 1};
                    planes = planes + 1;
                    %disp(q+(j-1)*num_z)
                end
            end
        else
            
            %colors(colors==drop)=[];
            %num_c = 3;
            for j=1:num_c
                for q=1:num_z
                    megastack(:,:,j,q,i,x)=nd_file{i,1}{q+(colors(j)-1)*num_z + t_ind, 1};
                    planes = planes + 1;
                end
            end
        end
        t_ind = planes + t_ind;
    end
    
end


%builds one gigantic stack to pull data from: X x Y x C x Z x P

displayimage=megastack(:,:,disp_colors,1,1);

imageToDisplay=getMulticolorImageforUI(displayimage,num_c);

%builds a single RGB stack (X x Y x 3) for display

img=imagesc(imageToDisplay(:,:,1));
imAX=img.Parent;
imageposition=[.2 .2 .75 .7];
imAX.Position=imageposition;



%set(gca,'XTick','none')
%gca.XTickLabel='none';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%DEFINING INITIAL UI ELEMENTS%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



zsliderpos=[figsize(1)*.2 figsize(2)*.03 figsize(1)*.75 figsize(2)*.025];

zcounterpos=[figsize(1)*.955 figsize(2)*.029 figsize(1)*.02 figsize(2)*.025];

if num_z>1
    z = uicontrol('Style', 'slider',...
        'Min',1,'Max',num_z,'Value',1,...
        'Position', zsliderpos,...
        'SliderStep', [1, 1] / (num_z - 1),...
        'Callback', {@getsliderpos,pts});
    
    zcounter = uicontrol('Style','text',...
        'Position',zcounterpos,...
        'String','1');
else
    z.Value=1;
end




psliderpos=[figsize(1)*.2 figsize(2)*.08 figsize(1)*.75 figsize(2)*.025];

pcounterpos=[figsize(1)*.955 figsize(2)*.078 figsize(1)*.02 figsize(2)*.025];

if num_p>1
    p = uicontrol('Style', 'slider',...
        'Min',1,'Max',num_p,'Value',1,...
        'Position', psliderpos,...
        'SliderStep', [1, 1] / (num_p - 1),...
        'Callback', {@getppos,pts});
    
    pcounter = uicontrol('Style','text',...
        'Position',pcounterpos,...
        'String','1');
else
    p.Value=1;
end

tsliderpos=[figsize(1)*.2 figsize(2)*.13 figsize(1)*.75 figsize(2)*.025];

tcounterpos=[figsize(1)*.955 figsize(2)*.128 figsize(1)*.02 figsize(2)*.025];

if num_t>1
    t = uicontrol('Style', 'slider',...
        'Min',1,'Max',num_t,'Value',1,...
        'Position', tsliderpos,...
        'SliderStep', [1, 1] / (num_t - 1),...
        'Callback', {@get_t_pos,pts});
    
    tcounter = uicontrol('Style','text',...
        'Position',tcounterpos,...
        'String','1');
else
    t.Value=1;
end

kpairbuttonpos=[figsize(1)*.02 figsize(2)*.9 figsize(1)*.10 figsize(2)*.025];

kpair = uicontrol('Style', 'pushbutton', 'String', 'Mark pairs',...
    'Position', kpairbuttonpos,...
    'Callback', {@setptstopairs,pts,pix_size,timepoints});

if num_c > 3
    
    chan_change_buttonpos=[figsize(1)*.02 figsize(2)*.33 figsize(1)*.10 figsize(2)*.025];
    
    chan_change = uicontrol('Style', 'pushbutton', 'String', 'Change color',...
        'Position', chan_change_buttonpos,...
        'Callback', {@recolor, pts});
    
    handles.disp_colors = disp_colors;
    
else
    handles.disp_colors = disp_colors;
end
%sets the callback function on the image to be "MarkKPairs"

timetrackbuttonpos=[figsize(1)*.02 figsize(2)*.6 figsize(1)*.10 figsize(2)*.025];

track_button = uicontrol('Style', 'pushbutton', 'String', 'Time Track',...
    'Position', timetrackbuttonpos,...
    'Callback', {@setptstotime,pts,pix_size,timepoints});

newfeatbuttonpos=[figsize(1)*.02 figsize(2)*.55 figsize(1)*.10 figsize(2)*.025];



savepairbuttonpos=[figsize(1)*.02 figsize(2)*.85 figsize(1)*.1 figsize(2)*.025];

savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
    'Position',savepairbuttonpos,...
    'Callback', {@savepairs,pts,pix_size});

%installs the button used to save pair data

openpairbuttonpos=[figsize(1)*.02 figsize(2)*.8 figsize(1)*.1 figsize(2)*.025];

openpair = uicontrol('Style', 'pushbutton', 'String', 'Open pair data',...
    'Position',openpairbuttonpos,...
    'Callback', {@openpairs,pix_size});
%intalls the button to open pair data

savetimebuttonpos=[figsize(1)*.02 figsize(2)*.5 figsize(1)*.1 figsize(2)*.025];

savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
    'Position',savetimebuttonpos,...
    'Callback', {@savetime,pts,pix_size});

%installs the button used to save pair data

opentimebuttonpos=[figsize(1)*.02 figsize(2)*.45 figsize(1)*.1 figsize(2)*.025];

opentimebutton = uicontrol('Style', 'pushbutton', 'String', 'Open time data',...
    'Position',opentimebuttonpos,...
    'Callback', {@opentime,pix_size});
%intalls the button to open pair data

deletepairtrackbuttonpos=[figsize(1)*.02 figsize(2)*.75 figsize(1)*.1 figsize(2)*.025];

deletepairtrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
    'Position',deletepairtrackbuttonpos,...
    'Callback', {@delpairtrack,pts,pix_size});
%intalls the button to delete the last tracked mark

deletetimetrackbuttonpos=[figsize(1)*.02 figsize(2)*.4 figsize(1)*.1 figsize(2)*.025];

deletetimetrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
    'Position',deletetimetrackbuttonpos,...
    'Callback', {@deltimetrack,pts,pix_size});

Intbuttonpos=[figsize(1)*.02 figsize(2)*.27 figsize(1)*.1 figsize(2)*.025];

Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
    'Position',Intbuttonpos,...
    'Callback', {@CalculateIntensities,pts,pix_size});

max_r=255;

rsliderpos=[figsize(1)*.02 figsize(2)*.17 figsize(1)*.12 figsize(2)*.025];

r = uicontrol('Style', 'slider',...
    'Min',0,'Max',max_r,'Value',255,...
    'Position', rsliderpos,...
    'SliderStep', [1 1] / (255 - 0),...
    'Callback', {@getRpos,pts,r_scaler,pix_size});

max_g=255;

gsliderpos=[figsize(1)*.02 figsize(2)*.11 figsize(1)*.12 figsize(2)*.025];


if num_c > 1
    g = uicontrol('Style', 'slider',...
        'Min',0,'Max',max_g,'Value',255,...
        'Position', gsliderpos,...
        'SliderStep', [1 1] / (255 - 0),...
        'Callback', {@getGpos,pts,g_scaler,pix_size});
else
    g.Value = 255;
end


max_b=255;

bsliderpos=[figsize(1)*.02 figsize(2)*.05 figsize(1)*.12 figsize(2)*.025];

if num_c > 2
    
    b = uicontrol('Style', 'slider',...
        'Min',0,'Max',max_b,'Value',255,...
        'Position', bsliderpos,...
        'SliderStep', [1 1] / (255 - 0),...
        'Callback', {@getBpos,pts,b_scaler,pix_size});
else
    b.Value = 255;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%   FUNCTIONS TO CHANGE T, P, Z    %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



    function ppos=getppos(source,event,pts)
        
        val=round(source.Value);
        stgpos = val;
        slcpos = round(z.Value);
        tpos = round(t.Value);
        
        multicolorimage = megastack(:,:,handles.disp_colors,slcpos,val, tpos);
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r.Value/255);
        
        if num_c > 1
            [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g.Value/255);
        end
        
        if num_c > 2
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b.Value/255);
        end
        
        h=findobj(gca,'Type','hggroup');
        delete(h);
        img.CData=getMulticolorImageforUI(multicolorimage,num_c);
        ppos=val;
        
        
        
        if isstruct(pts) == 1
            if pts(stgpos).datatype == 1;
                if pts(stgpos).num_kin ~= 0
                    K1check=find(pts(stgpos).K1coord(:,3)==slcpos & pts(stgpos).K1coord(:,4)==tpos);
                    
                    if isempty(K1check) == 0
                        h=viscircles(pts(stgpos).K1coord(K1check,1:2),4*ones(1,length(K1check)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                    if pts(stgpos).num_kin > 1
                        K2check=find(pts(stgpos).K2coord(:,3)==slcpos & pts(stgpos).K2coord(:,4)==tpos);
                        if isempty(K2check) == 0
                            h=viscircles(pts(stgpos).K2coord(K2check,1:2),4*ones(1,length(K2check)),'LineWidth',0.25);
                            h.Children(1).Color=orange;
                        end
                    end
                    %Redraws circles if they have been tracked using the Kpair tracker
                end
            elseif pts(i).datatype == 2;
                if pts(stgpos).num_kin ~= 0
                    Kcheck=find(pts(stgpos).coord(:,3)==slcpos & pts(stgpos).coord(:,4)==tpos);
                    if isempty(Kcheck) == 0
                        h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                end
            end
            numtextpos=[figsize(1)*.965 figsize(2)*.5 figsize(1)*.025 figsize(2)*.05];
            numtxt = uicontrol('Style','text',...
                'Position',numtextpos,...
                'String',num2str(pts(stgpos).num_kin),'FontSize',16);
            
        end
        
        
        
        
        pcounter = uicontrol('Style','text',...
            'Position',pcounterpos,...
            'String',num2str(stgpos));
    end

%function that changes the stage position using the slider while maintaining the
%z position

    function tpos=get_t_pos(source,event,pts)
        
        val= round(source.Value);
        stgpos = round(p.Value);
        slcpos = round(z.Value);
        tpos = round(val);
        
        multicolorimage = megastack(:,:,handles.disp_colors, slcpos, stgpos, val);
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r.Value/255);
        
        if num_c > 1
            [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g.Value/255);
        end
        
        if num_c > 2
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b.Value/255);
        end
        
        h=findobj(gca,'Type','hggroup');
        delete(h);
        img.CData=getMulticolorImageforUI(multicolorimage,num_c);
        
        
        
        if isstruct(pts) == 1
            if pts(stgpos).datatype == 1;
                if pts(stgpos).num_kin ~= 0
                    K1check=find(pts(stgpos).K1coord(:,3)==slcpos & pts(stgpos).K1coord(:,4)==tpos);
                    
                    if isempty(K1check) == 0
                        h=viscircles(pts(stgpos).K1coord(K1check,1:2),4*ones(1,length(K1check)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                    if pts(stgpos).num_kin > 1
                        K2check=find(pts(stgpos).K2coord(:,3)==slcpos & pts(stgpos).K2coord(:,4)==tpos);
                        if isempty(K2check) == 0
                            h=viscircles(pts(stgpos).K2coord(K2check,1:2),4*ones(1,length(K2check)),'LineWidth',0.25);
                            h.Children(1).Color=orange;
                        end
                    end
                    %Redraws circles if they have been tracked using the Kpair tracker
                end
            elseif pts(i).datatype == 2;
                if pts(stgpos).num_kin ~= 0
                    Kcheck=find(pts(stgpos).coord(:,3)==slcpos & pts(stgpos).coord(:,4)==tpos);
                    if isempty(Kcheck) == 0
                        h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                end
            end
            %Redraws circles if they have been tracked using the Kpair tracker
        end
        tcounter = uicontrol('Style','text',...
            'Position',tcounterpos,...
            'String',num2str(tpos));
    end

    function zpos=getsliderpos(source, event, pts)
        val=round(source.Value);
        zpos=round(val);
        stgpos = round(p.Value);
        slcpos = round(val);
        tpos = round(t.Value);
        h=findobj(gca,'Type','hggroup');
        delete(h);
        multicolorimage = (megastack(:,:,handles.disp_colors,val,stgpos, tpos));
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r.Value/255);
        
        if num_c > 1
            [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g.Value/255);
        end
        
        if num_c > 2
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b.Value/255);
        end
        
        img.CData=getMulticolorImageforUI(multicolorimage , num_c);
        
        
        if isstruct(pts) == 1
            if pts(stgpos).datatype == 1;
                if pts(stgpos).num_kin ~= 0
                    K1check=find(pts(stgpos).K1coord(:,3)==slcpos & pts(stgpos).K1coord(:,4)==tpos);
                    
                    if isempty(K1check) == 0
                        h=viscircles(pts(stgpos).K1coord(K1check,1:2),4*ones(1,length(K1check)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                    if pts(stgpos).num_kin > 1
                        K2check=find(pts(stgpos).K2coord(:,3)==slcpos & pts(stgpos).K2coord(:,4)==tpos);
                        if isempty(K2check) == 0
                            h=viscircles(pts(stgpos).K2coord(K2check,1:2),4*ones(1,length(K2check)),'LineWidth',0.25);
                            h.Children(1).Color=orange;
                        end
                    end
                    %Redraws circles if they have been tracked using the Kpair tracker
                end
            elseif pts(i).datatype == 2;
                if pts(stgpos).num_kin ~= 0
                    Kcheck=find(pts(stgpos).coord(:,3)==slcpos & pts(stgpos).coord(:,4)==tpos);
                    if isempty(Kcheck) == 0
                        h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                        h.Children(1).Color=cyan;
                    end
                end
            end
            %Redraws circles if they have been tracked using the Kpair tracker
        end
        %Redraws circles if they have been tracked using the Kpair tracker
        zcounter = uicontrol('Style','text',...
            'Position',zcounterpos,...
            'String',num2str(slcpos));
    end

%function that changes the zposition using the slider while maintaining the
%stage position

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%      TRACKING FUNCTIONS       %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function pts=setptstopairs(source, event,pts, pix_size, timepoints)
        uiwait(msgbox('You turned on The object pair marking option. Please click on an object, and then its complement (eg. a kinetochore and its sister). Please do not press this button again until you press the "Pairs Done" button.'))
        
        stgpos = round(p.Value);
        slcpos = round(z.Value);
        tpos = round(t.Value);
        
        for i=1:num_p
            s(i).num_kin=0;
            s(i).K1coord=[];
            s(i).K2coord=[];
            s(i).timepoints = timepoints(:,i);
            s(i).datatype = 1;
            
        end
        pts=s;
        img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
        deletepairtrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
            'Position',deletepairtrackbuttonpos,...
            'Callback', {@delpairtrack,pts,pix_size});
        
        numtextpos=[figsize(1)*.965 figsize(2)*.5 figsize(1)*.025 figsize(2)*.05];
        numtxt = uicontrol('Style','text',...
            'Position',numtextpos,...
            'String',num2str(pts(stgpos).num_kin),'FontSize',16);
    end

    function ffff=setptstotime(source, event, pts, pix_size, timepoints)
        uiwait(msgbox('You turned on the time tracking option. Select "Track New Feature" to get started.'))
        
        stgpos = round(p.Value);
        slcpos = round(z.Value);
        tpos = round(t.Value);
        
        for i=1:num_p
            s(i).num_kin=0;
            s(i).timepoints = timepoints(:,i);
            s(i).datatype = 2;
            
            s(i).coord=[];
        end
        pts=s;
        
        figure(1)
        
        mark_feature_ui = uicontrol('Style', 'pushbutton', 'String', 'Track New Feature',...
            'Position', newfeatbuttonpos,...
            'Callback', {@mark_new_feat, pts, pix_size});
        
        
        
        
        
        
        
        deletetimetrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
            'Position',deletetimetrackbuttonpos,...
            'Callback', {@deltimetrack,pts,pix_size});
    end

%function that sets callback function on the image to be "MarkKPairs" and builds the struct "pts" that will hold all the data.

    function pts=mark_new_feat(source, eventdata, pts, pixsize)
        
        feat_name = inputdlg('What is the name of this feature?', 'name', 1);
        
        stgpos = round(p.Value);
        slcpos = round(z.Value);
        tpos = round(t.Value);
        
        
        if pts(stgpos).num_kin == 0;
            pts(stgpos).feat_name=feat_name;
        else
            pts(stgpos).feat_name{pts(stgpos).num_kin+1} = feat_name{1};
            
        end
        pts(stgpos).num_kin = pts(stgpos).num_kin + 1;
        img.ButtonDownFcn = {@MarkTimeTrack ,pts, pix_size};
        
        mark_feature_ui = uicontrol('Style', 'pushbutton', 'String', 'Track New Feature',...
            'Position', newfeatbuttonpos,...
            'Callback', {@mark_new_feat,pts,pix_size});
        
        savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
            'Position',savetimebuttonpos,...
            'Callback', {@savetime,pts,pix_size});
        
        
    end

    function pts=MarkTimeTrack(source, eventdata, pts, pixsize)
        
        AX=source.Parent;
        coord = get(AX, 'CurrentPoint');
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        coord = [coord(1,1) coord(1,2) slcpos tpos pts(stgpos).num_kin];
        
        
        if isempty(pts(stgpos).coord) == 0
            [row, c] = find(pts(stgpos).coord(pts(stgpos).coord(:, 4) == tpos , :));
            matchcoords = pts(stgpos).coord(pts(stgpos).coord(:, 4) == tpos , :);
            if isempty(matchcoords) == 1
                pts(stgpos).coord = [pts(stgpos).coord; coord];
            elseif ismember(pts(stgpos).num_kin, matchcoords(:,5)) == 1
                pts(stgpos).coord(row(matchcoords(:,5) == pts(stgpos).num_kin), :)...
                    = coord;
            else
                pts(stgpos).coord = [pts(stgpos).coord; coord];
            end
        else
            
            pts(stgpos).coord = [pts(stgpos).coord; coord];
        end
        
        
        
        
        img.ButtonDownFcn = {@MarkTimeTrack ,pts, pix_size};
        if tpos < num_t;
            h=findobj(gca,'Type','hggroup');
            delete(h);
            multicolorimage = (megastack(:,:,handles.disp_colors, slcpos, stgpos, tpos+1));
            
            [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r.Value/255);
            
            if num_c > 1
                [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g.Value/255);
            end
            
            if num_c > 2
                [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b.Value/255);
            end
            
            img.CData=getMulticolorImageforUI(multicolorimage , num_c);
            
            tcounter = uicontrol('Style','text',...
                'Position',tcounterpos,...
                'String',num2str(tpos + 1 ));
            
            if pts(stgpos).num_kin > 1
                Kcheck=find(pts(stgpos).coord(:,3) == slcpos & pts(stgpos).coord(:,4) == tpos + 1);
                if isempty(Kcheck) == 0
                    h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                    h.Children(1).Color=cyan;
                end
            end
            if num_t>1
                t = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_t,'Value',t.Value + 1,...
                    'Position', tsliderpos,...
                    'SliderStep', [1, 1] / (num_t - 1),...
                    'Callback', {@get_t_pos,pts});
                
                
            end
        else
            if num_t>1
                t = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_t,'Value',t.Value,...
                    'Position', tsliderpos,...
                    'SliderStep', [1, 1] / (num_t - 1),...
                    'Callback', {@get_t_pos,pts});
                
                
            end
            h=viscircles(coord(1:2),4,'LineWidth',0.25);
            h.Children(1).Color=cyan;
        end
        if num_z>1
            z = uicontrol('Style', 'slider',...
                'Min',1,'Max',num_z,'Value',z.Value,...
                'Position', zsliderpos,...
                'SliderStep', [1, 1] / (num_z - 1),...
                'Callback', {@getsliderpos,pts});
        end
        if num_p>1
            p = uicontrol('Style', 'slider',...
                'Min',1,'Max',num_p,'Value',p.Value,...
                'Position', psliderpos,...
                'SliderStep', [1, 1] / (num_p - 1),...
                'Callback', {@getppos,pts});
        end
        
        
        
        %Recalls all of the sliders to update the pts struct within them
        
        mark_feature_ui = uicontrol('Style', 'pushbutton', 'String', 'Track New Feature',...
            'Position', newfeatbuttonpos,...
            'Callback', {@mark_new_feat,pts,pix_size});
        
        deletetimetrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
            'Position',deletetimetrackbuttonpos,...
            'Callback', {@deltimetrack,pts,pix_size});
        
        savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
            'Position',savetimebuttonpos,...
            'Callback', {@savetime,pts,pix_size});
        Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
            'Position',Intbuttonpos,...
            'Callback', {@CalculateIntensities,pts,pix_size});
        
    end

    function pts=MarkKPairs(source, eventdata, pts, pixsize)
        AX=source.Parent;
        coord = get(AX, 'CurrentPoint');
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        coord = [coord(1,1) coord(1,2) slcpos tpos];
        
        pts(stgpos).num_kin=pts(stgpos).num_kin+1;
        
        if rem(pts(stgpos).num_kin,2)==1
            pts(stgpos).K1coord = [pts(stgpos).K1coord; coord];
            h=viscircles(coord(1:2),4,'LineWidth',0.25);
            h.Children(1).Color=cyan;
            
        else
            pts(stgpos).K2coord = [pts(stgpos).K2coord; coord];
            h=viscircles(coord(1:2),4,'LineWidth',0.25);
            h.Children(1).Color=orange;
            
        end
        img.ButtonDownFcn={@MarkKPairs,pts};
        if num_z>1
            z = uicontrol('Style', 'slider',...
                'Min',1,'Max',num_z,'Value',z.Value,...
                'Position', zsliderpos,...
                'SliderStep', [1, 1] / (num_z - 1),...
                'Callback', {@getsliderpos,pts});
        end
        if num_p>1
            p = uicontrol('Style', 'slider',...
                'Min',1,'Max',num_p,'Value',p.Value,...
                'Position', psliderpos,...
                'SliderStep', [1, 1] / (num_p - 1),...
                'Callback', {@getppos,pts});
        end
        
        if num_t>1
            t = uicontrol('Style', 'slider',...
                'Min',1,'Max',num_t,'Value',t.Value,...
                'Position', tsliderpos,...
                'SliderStep', [1, 1] / (num_t - 1),...
                'Callback', {@get_t_pos,pts});
        end
        
        %Recalls all of the sliders to update the pts struct within them
        
        savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
            'Position',savepairbuttonpos,...
            'Callback', {@savepairs,pts,pix_size});
        %updates the save function to save the newest data
        
        deletepairtrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
            'Position',deletepairtrackbuttonpos,...
            'Callback', {@delpairtrack,pts,pix_size});
        
        Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
            'Position',Intbuttonpos,...
            'Callback', {@CalculateIntensities,pts,pix_size});
        
        numtextpos=[figsize(1)*.965 figsize(2)*.5 figsize(1)*.025 figsize(2)*.05];
        numtxt = uicontrol('Style','text',...
            'Position',numtextpos,...
            'String',num2str(pts(stgpos).num_kin),'FontSize',16);
        uicontrol(z);
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%      SAVING/LOADING FUNCTIONS       %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [pix_size]=savepairs(source, event, pts, pix_size)
        pix_size = WritePairDataToFile_ImAlGui( pts, pix_size );
        img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
        savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
            'Position',savepairbuttonpos,...
            'Callback', {@savepairs,pts,pix_size});
    end

    function [pix_size]=savetime(source, event, pts, pix_size)
        pix_size = WriteTimeDataToFile_ImAlGui( pts, pix_size );
        img.ButtonDownFcn={@MarkTimeTrack,pts, pix_size};
        savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
            'Position',savetimebuttonpos,...
            'Callback', {@savetime,pts,pix_size});
    end

    function [pts]=openpairs(source,event,pix_size);
        check=questdlg('Proceeding will clear the currently tracked data on the UI. Continue?','Save data?','Yes','No','Yes');
        %makes sure you don't accidentally erase your progess on the figure
        if strcmp(check,'Yes')==1
            [ pts, data_matrix, column_labels ] = ReadPairDataFromFile_ImAlGui;
            %reads data from file. Might use the other inputs in a later
            %build.
            img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
            stgpos=round(p.Value);
            slcpos=round(z.Value);
            tpos = round(t.Value);
            savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
                'Position',savepairbuttonpos,...
                'Callback', {@savepairs,pts,pix_size});
            if num_z>1
                z = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_z,'Value',z.Value,...
                    'Position', zsliderpos,...
                    'SliderStep', [1, 1] / (num_z - 1),...
                    'Callback', {@getsliderpos,pts});
            end
            if num_p>1
                p = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_p,'Value',p.Value,...
                    'Position', psliderpos,...
                    'SliderStep', [1, 1] / (num_p - 1),...
                    'Callback', {@getppos,pts});
            end
            
            if num_t>1
                t = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_t,'Value',t.Value,...
                    'Position', tsliderpos,...
                    'SliderStep', [1, 1] / (num_t - 1),...
                    'Callback', {@get_t_pos,pts});
            end
            deletepairtrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
                'Position',deletepairtrackbuttonpos,...
                'Callback', {@delpairtrack,pts,pix_size});
            if num_p > 1
                stgpos = round(p.Value);
            else
                stgpos=1;
            end
            
            if num_z > 1
                slcpos = round(z.Value);
            else
                slcpos = 1;
            end
            
            if num_t > 1
                timepos = round(t.Value);
            else
                timepos = 1;
            end
            
            h=findobj( gca, 'Type', 'hggroup' );
            delete( h );
            
            if isempty(pts( stgpos ).K1coord) == 1
                while isempty(pts( stgpos ).K1coord) == 1
                    stgpos = stgpos + 1;
                end
            end
            
            K1check=find( pts( stgpos ).K1coord( :, 3 ) == slcpos...
                & pts( stgpos ).K1coord( :, 4 ) == timepos);
            K2check=find( pts( stgpos ).K2coord( :, 3 ) == slcpos...
                & pts( stgpos ).K2coord( :, 4 ) == timepos);
            
            if isempty( K1check ) == 0
                h=viscircles(pts(stgpos).K1coord(K1check,1:2),4*ones(1,length(K1check)),'LineWidth',0.25);
                h.Children(1).Color=cyan;
            end
            
            if isempty( K2check ) == 0
                h=viscircles(pts(stgpos).K2coord(K2check,1:2),4*ones(1,length(K2check)),'LineWidth',0.25);
                h.Children(1).Color=orange;
            end
            Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
                'Position',Intbuttonpos,...
                'Callback', {@CalculateIntensities,pts,pix_size});
            
            numtextpos=[figsize(1)*.965 figsize(2)*.5 figsize(1)*.025 figsize(2)*.05];
            numtxt = uicontrol('Style','text',...
                'Position',numtextpos,...
                'String',num2str(pts(stgpos).num_kin),'FontSize',16);
        end
        
    end

    function [pts]=opentime(source,event,pix_size)
        check=questdlg('Proceeding will clear the currently tracked data on the UI. Continue?','Save data?','Yes','No','Yes');
        %makes sure you don't accidentally erase your progess on the figure
        if strcmp(check,'Yes')==1
            [ pts, data_matrix, column_labels ] = ReadTimeDataFromFile_ImAlGui;
            %reads data from file. Might use the other inputs in a later
            %build.
            img.ButtonDownFcn={@MarkTimeTrack,pts, pix_size};
            stgpos=round(p.Value);
            slcpos=round(z.Value);
            tpos = round(t.Value);
            savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
                'Position',savetimebuttonpos,...
                'Callback', {@savetime,pts,pix_size});
            if num_z>1
                z = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_z,'Value',z.Value,...
                    'Position', zsliderpos,...
                    'SliderStep', [1, 1] / (num_z - 1),...
                    'Callback', {@getsliderpos,pts});
            end
            if num_p>1
                p = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_p,'Value',p.Value,...
                    'Position', psliderpos,...
                    'SliderStep', [1, 1] / (num_p - 1),...
                    'Callback', {@getppos,pts});
            end
            
            if num_t>1
                t = uicontrol('Style', 'slider',...
                    'Min',1,'Max',num_t,'Value',t.Value,...
                    'Position', tsliderpos,...
                    'SliderStep', [1, 1] / (num_t - 1),...
                    'Callback', {@get_t_pos,pts});
                
                tcounter = uicontrol('Style','text',...
                    'Position',tcounterpos,...
                    'String',num2str(tpos));
            end
            deletetimetrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
                'Position',deletetimetrackbuttonpos,...
                'Callback', {@deltimetrack,pts,pix_size});
            if num_p > 1
                stgpos = round(p.Value);
            else
                stgpos=1;
            end
            
            if num_z > 1
                slcpos = round(z.Value);
            else
                slcpos = 1;
            end
            
            if num_t > 1
                timepos = round(t.Value);
            else
                timepos = 1;
            end
            
            h=findobj( gca, 'Type', 'hggroup' );
            delete( h );
            
            Kcheck=find( pts( stgpos ).coord( :, 3 ) == slcpos...
                & pts( stgpos ).coord( :, 4 ) == timepos);
            
            
            if isempty( Kcheck ) == 0
                h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                h.Children(1).Color=cyan;
            end
            
            mark_feature_ui = uicontrol('Style', 'pushbutton', 'String', 'Track New Feature',...
                'Position', newfeatbuttonpos,...
                'Callback', {@mark_new_feat,pts,pix_size});
            
            Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
                'Position',Intbuttonpos,...
                'Callback', {@CalculateIntensities,pts,pix_size});
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%      DELETING FUNCTIONS       %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [pts]=delpairtrack(source, event, pts, pix_size)
        if isstruct(pts) ==1
            if num_p > 1
                stgpos = round(p.Value);
            else
                stgpos=1;
            end
            
            if num_z > 1
                slcpos = round(z.Value);
            else
                slcpos = 1;
            end
            
            if num_t > 1
                tpos = round(t.Value);
            else
                tpos = 1;
            end
            
            if pts(stgpos).num_kin > 0
                
                
                if rem(pts(stgpos).num_kin, 2)== 1
                    pts(stgpos).K1coord(size(pts(stgpos).K1coord, 1),:) = [];
                else
                    pts(stgpos).K2coord(size(pts(stgpos).K1coord, 1), :) = [];
                end
                %Delete the coordinate
                pts( stgpos ). num_kin = pts( stgpos ).num_kin - 1;
                %Brings the count down
                h=findobj( gca, 'Type', 'hggroup' );
                delete( h );
                
                K1check=find( pts( stgpos ).K1coord( :, 3 ) == slcpos...
                    & pts( stgpos ).K1coord( :, 4 ) == tpos);
                K2check=find( pts( stgpos ).K2coord( :, 3 ) == slcpos...
                    & pts( stgpos ).K2coord( :, 4 ) == tpos);
                
                if isempty( K1check ) == 0
                    h=viscircles(pts(stgpos).K1coord(K1check,1:2),4*ones(1,length(K1check)),'LineWidth',0.25);
                    h.Children(1).Color=cyan;
                end
                
                if isempty( K2check ) == 0
                    h=viscircles(pts(stgpos).K2coord(K2check,1:2),4*ones(1,length(K2check)),'LineWidth',0.25);
                    h.Children(1).Color=orange;
                end
                
                if num_z>1
                    z = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_z,'Value',z.Value,...
                        'Position', zsliderpos,...
                        'SliderStep', [1, 1] / (num_z - 1),...
                        'Callback', {@getsliderpos,pts});
                end
                if num_p>1
                    p = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_p,'Value',p.Value,...
                        'Position', psliderpos,...
                        'SliderStep', [1, 1] / (num_p - 1),...
                        'Callback', {@getppos,pts});
                end
                
                if num_t>1
                    t = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_t,'Value',t.Value,...
                        'Position', tsliderpos,...
                        'SliderStep', [1, 1] / (num_t - 1),...
                        'Callback', {@get_t_pos,pts});
                end
                
                savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
                    'Position',savepairbuttonpos,...
                    'Callback', {@savepairs,pts,pix_size});
                
                openpair = uicontrol('Style', 'pushbutton', 'String', 'Open pair data',...
                    'Position',openpairbuttonpos,...
                    'Callback', {@openpairs,pix_size});
                
                img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
                
                deletepairtrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
                    'Position',deletepairtrackbuttonpos,...
                    'Callback', {@delpairtrack,pts,pix_size});
                
                
                %removes the all the circles
                
                numtextpos=[figsize(1)*.965 figsize(2)*.5 figsize(1)*.025 figsize(2)*.05];
                numtxt = uicontrol('Style','text',...
                    'Position',numtextpos,...
                    'String',num2str(pts(stgpos).num_kin),'FontSize',16);
                
            else
                msgbox( 'No tracks to delete!' )
            end
        end
        Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
            'Position',Intbuttonpos,...
            'Callback', {@CalculateIntensities,pts,pix_size});
    end

    function [pts]=deltimetrack(source, event, pts, pix_size)
        if isstruct(pts) ==1
            if num_p > 1
                stgpos = round(p.Value);
            else
                stgpos=1;
            end
            
            if num_z > 1
                slcpos = round(z.Value);
            else
                slcpos = 1;
            end
            
            if num_t > 1
                tpos = round(t.Value);
            else
                tpos = 1;
            end
            
            if isempty(pts(stgpos).coord) == 0
                
                
                
                pts(stgpos).coord(size(pts(stgpos).coord, 1), :) = [];
                
                %Delete the coordinate
                
                %Brings the count down
                h=findobj( gca, 'Type', 'hggroup' );
                delete( h );
                
                Kcheck=find( pts( stgpos ).coord( :, 3 ) == slcpos...
                    & pts( stgpos ).coord( :, 4 ) == tpos);
                
                
                if isempty( Kcheck ) == 0
                    h=viscircles(pts(stgpos).coord(Kcheck,1:2),4*ones(1,length(Kcheck)),'LineWidth',0.25);
                    h.Children(1).Color=cyan;
                end
                
                
                
                if num_z>1
                    z = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_z,'Value',z.Value,...
                        'Position', zsliderpos,...
                        'SliderStep', [1, 1] / (num_z - 1),...
                        'Callback', {@getsliderpos,pts});
                end
                if num_p>1
                    p = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_p,'Value',p.Value,...
                        'Position', psliderpos,...
                        'SliderStep', [1, 1] / (num_p - 1),...
                        'Callback', {@getppos,pts});
                end
                
                if num_t>1
                    t = uicontrol('Style', 'slider',...
                        'Min',1,'Max',num_t,'Value',t.Value,...
                        'Position', tsliderpos,...
                        'SliderStep', [1, 1] / (num_t - 1),...
                        'Callback', {@get_t_pos,pts});
                end
                
                savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
                    'Position',savetimebuttonpos,...
                    'Callback', {@savetime,pts,pix_size});
                
                opentimebutton = uicontrol('Style', 'pushbutton', 'String', 'Open time data',...
                    'Position',opentimebuttonpos,...
                    'Callback', {@opentime,pix_size});
                
                img.ButtonDownFcn={@MarkTimeTrack,pts, pix_size};
                
                deletetimetrack = uicontrol('Style', 'pushbutton', 'String', 'Delete last point',...
                    'Position',deletetimetrackbuttonpos,...
                    'Callback', {@deltimetrack,pts,pix_size});
                
                
                %removes the all the circles
                
            else
                msgbox( 'No tracks to delete!' )
            end
        end
        Ints = uicontrol('Style', 'pushbutton', 'String', 'Calculate Intensities',...
            'Position',Intbuttonpos,...
            'Callback', {@CalculateIntensities,pts,pix_size});
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%      Color SCALING FUNCTIONS       %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [r_scaler] = getRpos(source, events, pts, r_scaler, pix_size)
        
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        
        val=(source.Value);
        
        r_scaler = val / 255;
        
        g_scaler = g.Value / 255;
        
        b_scaler = b.Value / 255;
        
        multicolorimage = ( megastack( :, :, handles.disp_colors, slcpos, stgpos, tpos));
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r_scaler);
        
        
        if num_c > 1
            [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g_scaler);
        end
        
        if num_c > 2
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b_scaler);
        end
        
        img.CData=getMulticolorImageforUI(multicolorimage, num_c);
        
        
        
    end


    function [g_scaler] = getGpos(source, events, pts, g_scaler, pix_size)
        val=(source.Value);
        
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        
        g_scaler = val / 255;
        
        r_scaler = r.Value / 255;
        
        b_scaler = b.Value / 255;
        
        multicolorimage = ( megastack( :, :, handles.disp_colors, slcpos, stgpos, tpos));
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r_scaler);
        
        [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g_scaler);
        
        if num_c > 2
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b_scaler);
        end
        
        img.CData=getMulticolorImageforUI(multicolorimage, num_c);
        
        
        
        
    end

    function [b_scaler] = getBpos(source, events, pts, b_scaler, pix_size)
        val=(source.Value);
        
        b_scaler = val / 255;
        
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        
        r_scaler = r.Value / 255;
        
        g_scaler = g.Value / 255;
        
        multicolorimage = ( megastack( :, :, handles.disp_colors, slcpos, stgpos, tpos));
        
        [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r_scaler);
        
        [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g_scaler);
        
        [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b_scaler);
        
        img.CData=getMulticolorImageforUI(multicolorimage, num_c);
        
        
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%      INTENSITY FUNCTIONS       %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [intesities]=CalculateIntensities(source, event, pts, pix_size)
        rect_size=str2double(inputdlg('What size of square will you use?','Square size',1,...
            {'7'}));
        stgpos=round(p.Value);
        slcpos=round(z.Value);
        tpos = round(t.Value);
        
        if num_z>1
            check = questdlg( 'Do you want to sum over all z-Positions?','Z stack?','Yes','No','No' );
        else
            check = 'No';
        end
        
        for i = 1:numel(pts)
            if pts(i).datatype == 1 && pts(i).num_kin > 0;
                int1 = [];
                int2 = [];
                
                coord1 = pts(i).K1coord;
                coord2 = pts(i).K2coord;
                for q = 1:num_c
                    tempint1 = [];
                    tempint2 = [];
                    for j=1:size(coord1,1)
                        if strcmp(check, 'No') == 1
                            x1 = coord1(j,1);
                            y1 = coord1(j,2);
                            z1 = coord1(j,3);
                            t1 = coord1(j,4);
                            x2 = coord2(j,1);
                            y2 = coord2(j,2);
                            z2 = coord2(j,3);
                            t2 = coord2(j,4);
                            [ int ] = IntCalc_ImAlGui( megastack( :, :, q, z1, i, t1) , [x1 y1], rect_size );
                            tempint1 = [tempint1; int];
                            [ int ] = IntCalc_ImAlGui( megastack( :, :, q, z2, i, t2) , [x2 y2], rect_size );
                            tempint2 = [tempint2; int];
                        elseif strcmp(check, 'Yes') == 1
                            x1 = coord1(j,1);
                            y1 = coord1(j,2);
                            t1 = coord1(j,4);
                            x2 = coord2(j,1);
                            y2 = coord2(j,2);
                            t2 = coord2(j,4);
                            for h = 1:num_z
                                
                                z1 = h;
                                
                                z2 = h;
                                
                                [ z_int_1(h) ] = IntCalc_ImAlGui( megastack( :, :, q, z1, i, t1) , [x1 y1], rect_size );
                                
                                
                                [ z_int_2(h) ] = IntCalc_ImAlGui( megastack( :, :, q, z2, i, t2) , [x2 y2], rect_size );
                                
                                
                            end
                            
                            tempint1 = [tempint1; sum(z_int_1)];
                            
                            tempint2 = [tempint2; sum(z_int_2)];
                            
                            
                        end
                    end
                    int1 = [int1 tempint1];
                    int2 = [int2 tempint2];
                end
                pts(i).K1_Intensities = int1;
                pts(i).K2_Intensities = int2;
            elseif pts(i).datatype == 2 && pts(i).num_kin > 0;
                int1 = [];
                
                
                coord= pts(i).coord;
                
                for q = 1:num_c
                    tempint = [];
                    
                    
                    
                    for j=1:size(coord,1)
                        
                        if strcmp(check, 'No') == 1
                            
                            x1 = coord(j,1);
                            y1 = coord(j,2);
                            z1 = coord(j,3);
                            t1 = coord(j,4);
                            
                            [ int ] = IntCalc_ImAlGui( megastack( :, :, q, z1, i, t1) , [x1 y1], rect_size );
                            tempint = [tempint; int];
                            
                        elseif strcmp(check, 'Yes') == 1
                            
                            x1 = coord(j,1);
                            y1 = coord(j,2);
                            
                            t1 = coord(j,4);
                            
                            for h = 1:num_z
                                
                                z1 = h;
                                
                                [  z_int_1(h) ] = IntCalc_ImAlGui( megastack( :, :, q, z1, i, t1) , [x1 y1], rect_size );
                            end
                            
                            tempint = [tempint; sum( z_int_1 )];
                        end
                        
                        
                    end
                    int1 = [int1 tempint];
                    
                end
                pts(i).Intensities = int1;
                
            end
            
        end
        
        if pts(1).datatype == 2
            pix_size = WriteTimeDataToFile_ImAlGui( pts, pix_size, 'Intensities' );
            img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
            savetimebutton = uicontrol('Style', 'pushbutton', 'String', 'Save time data',...
                'Position',savetimebuttonpos,...
                'Callback', {@savetime,pts,pix_size});
        else
            pix_size = WritePairDataToFile_ImAlGui( pts, pix_size, 'Intensities' );
            img.ButtonDownFcn={@MarkKPairs,pts, pix_size};
            savepair = uicontrol('Style', 'pushbutton', 'String', 'Save pair data',...
                'Position',savepairbuttonpos,...
                'Callback', {@savepairs,pts,pix_size});
        end
        
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%       CHANGE CHANNELS       %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [disp_colors] = recolor(source, events, pts)
        d = figure('Position',[300 300 250 170],'Name','Select One');
        
        txt = uicontrol('Parent',d,...
            'Style','text',...
            'Position',[20 130 210 20],...
            'String','Select a channel to DROP');
        
        bg = uibuttongroup('Parent',d,...
            'Visible','off','Position',[0.25 .35 0.5 0.4], ...
            'SelectionChangedFcn',{@bg_value, colors});
        
        r1 = uicontrol(bg,'Style',...
            'radiobutton',...
            'Units', 'normalized',...
            'Position', [0.2 0.8 .7 .2],...
            'String','Channel 1',...
            'HandleVisibility','off');
        
        r2 = uicontrol(bg,'Style',...
            'radiobutton',...
            'Units', 'normalized',...
            'Position', [0.2 0.55 .7 .2],...
            'String','Channel 2',...
            'HandleVisibility','off');
        
        r3 = uicontrol(bg,'Style',...
            'radiobutton',...
            'Units', 'normalized',...
            'Position', [0.2 0.3 .7 .2],...
            'String','Channel 3',...
            'HandleVisibility','off');
        
        r4 = uicontrol(bg,'Style',...
            'radiobutton',...
            'Units', 'normalized',...
            'Position', [0.2 0.05 .7 .2],...
            'String','Channel 4',...
            'HandleVisibility','off');
        
        btn = uicontrol('Parent',d,...
            'Position',[89 20 70 25],...
            'String','Close',...
            'Callback','delete(gcf)');
        
        bg.Visible = 'on';
        
        
        
        % Wait for d to close before running to completion
        
        % uiwait(d);
        
        function disp_colors = bg_value(source, event, colors)
            disp([event.NewValue.String ' dropped']);
            channel = str2double(event.NewValue.String(length(event.NewValue.String)));
            
            disp_colors = colors;
            
            disp_colors(ismember(disp_colors, channel)) = [];
            
            stgpos=round(p.Value);
            slcpos=round(z.Value);
            tpos = round(t.Value);
            
            g_scaler = g.Value / 255;
            
            r_scaler = r.Value / 255;
            
            b_scaler = b.Value / 255;
            
            multicolorimage = ( megastack( :, :, disp_colors, slcpos, stgpos, tpos));
            
            [ multicolorimage( :, :, 1 ) ] = scaleimage(multicolorimage( :, :, 1 ), r_scaler);
            
            [ multicolorimage( :, :, 2 ) ] = scaleimage(multicolorimage( :, :, 2 ), g_scaler);
            
            [ multicolorimage( :, :, 3 ) ] = scaleimage(multicolorimage( :, :, 3 ), b_scaler);
            
            img.CData=getMulticolorImageforUI(multicolorimage, num_c);
            
            handles.disp_colors = disp_colors;
            
            
            %disp(disp_colors)
            
        end
        
    end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%           TEXT LABELS       %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if num_z>1
    ztextpos=[figsize(1)*.15 figsize(2)*.05 figsize(1)*.025 figsize(2)*.025];
    ztxt = uicontrol('Style','text',...
        'Position',ztextpos,...
        'String','z');
end
if num_p>1
    ptextpos=[figsize(1)*.15 figsize(2)*.1 figsize(1)*.025 figsize(2)*.025];
    ptxt = uicontrol('Style','text',...
        'Position',ptextpos,...
        'String','p');
end

if num_t>1
    ttextpos=[figsize(1)*.15 figsize(2)*.13 figsize(1)*.025 figsize(2)*.025];
    ttxt = uicontrol('Style','text',...
        'Position',ttextpos,...
        'String','t');
end

if num_c>1
    rtextpos=[figsize(1)*.07 figsize(2)*.2 figsize(1)*.025 figsize(2)*.025];
    rtxt = uicontrol('Style','text',...
        'Position',rtextpos,...
        'String','r');
else
    rtextpos=[figsize(1)*.07 figsize(2)*.2 figsize(1)*.025 figsize(2)*.025];
    rtxt = uicontrol('Style','text',...
        'Position',rtextpos,...
        'String','Brightess/Contrast');
end

if num_c>1
    gtextpos=[figsize(1)*.07 figsize(2)*.14 figsize(1)*.025 figsize(2)*.025];
    gtxt = uicontrol('Style','text',...
        'Position',gtextpos,...
        'String','g');
end

if num_c>2
    btextpos=[figsize(1)*.07 figsize(2)*.08 figsize(1)*.025 figsize(2)*.025];
    rtxt = uicontrol('Style','text',...
        'Position',btextpos,...
        'String','b');
end

end

function [scaled]=scaleimage(raw,scalefactor)

max_int = max( raw( : ) );

scaler = max_int * scalefactor;

scaled = raw;

scaled( scaled > scaler) = scaler;


end


% % % % % % %
% % % % % % %     function rlevel=getsliderpos(source,event)
% % % % % % %     val=round(source.Value);
% % % % % % %     img.CData=getMulticolorImageforUI(megastack(:,:,1:num_c,val,ppos),num_c);
% % % % % % %     zpos=val;
% % % % % % %     end
% % % % % % %
