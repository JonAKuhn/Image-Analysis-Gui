
function [ pix_size, filename ] = WriteTimeDataToFile_ImAlGui(varargin )
%Writes data from "Time Track" button on the gui to an XLS File

data=varargin{1};
%pulls out struct tracking data

if length(varargin)>1
    default_pix_size={num2str(varargin{2})};
else
    default_pix_size={'0.105'};
end
%pulls out a default pixel size, if stated.

if length(varargin)>2
    default_filename=varargin{3};
else
    defaultfilename='Tracking File.xls';
end
%pulls out a default pixel size, if stated.


data_matrix=[];

%Empty vector that will contain the pair data from the struct data 
%in a format the will write well to an excel sheet  

num_p = numel(data);

%gets position number
timepoints = [];
ind = 1;
for i=1:numel(data)
    if data(i).num_kin>0
        object(1, ind:ind + data(i).num_kin-1) = data(i).feat_name;
        object(2, ind:ind + data(i).num_kin-1) = num2cell((ind:ind + data(i).num_kin-1));
        object(3, ind:ind + data(i).num_kin-1) = ...
            num2cell(i * ones(1,data(i).num_kin));
        tempmatrix=[data(i).coord i*ones(size(data(i).coord,1),1)];
        %Builds a matrix with all kinetochore coordinate data  for a given
        %stage position as well as the position itself
        data_matrix=[data_matrix; tempmatrix];
    end
    timepoints = [timepoints data(i).timepoints];
end

data_key={'x (pixels)' 'y (pixels)' 'z' 't' 'object number' 'Stage Position'...
    'Number of total positions' 'Timepoints (seconds)'};

%text key that will tell you what each column represents

pix_size=inputdlg('What is the pixel size in microns?','Pixel Size',1,...
    default_pix_size);

%Sets Pixel Size


[filename,pathname] = uiputfile('.xls');

celldata=num2cell(data_matrix);

celldata{1,7}=num_p;


celldata(1:size(timepoints,1),8 : 8 + size(timepoints,2) - 1) = num2cell(timepoints); 

%adds in the total number of positions. Important for reconstructing the
%data struct.

sheetdata=[data_key; celldata];

cd(pathname)

pix_size=str2num(pix_size{1});

xlswrite(filename, sheetdata);

xlswrite(filename, object, 2);







end

