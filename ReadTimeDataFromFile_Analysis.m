function [ data_struct, data_matrix, column_labels, obj_struct] = ReadTimeDataFromFile_Analysis(varargin)
%Reads data made from the write pair data ImAlGui code back into the image
%analysis GUI. Outputs the neccessary struct, but also a matrix containing
%all the data, as well as a series of labels indicating the values in
%columns
FileName = varargin{1};

if length(varargin) > 1
     intcheck = strcmp(varargin{2}, 'Intensities');
else
    intcheck = 0;
end


[ data, column_labels, raw] = xlsread(FileName, 'Sheet1');
[objdata, objtxt, raw] = xlsread(FileName, 'Sheet2');
if intcheck == 1
    [intdata, dummy, meh] = xlsread(FileName, 'Sheet3');
end
%get excel file

data_matrix = data(isnan(data(:,1))==0, 1:6);



num_p = (data(isnan(data(:, 7)) == 0,7));

num_t = (max(data_matrix(:,4)));

timepoints = data(:, 8 : 8 + num_p - 1);
timepoints(isnan(timepoints)==1) = [];

time_column = [];

    
    
%seperates out the data that goes back in the struct vs the number of
%stage position the goes back in the struct. Gets the number of positions



%defines the columns

stage_positions = unique(data_matrix(:, 6));

%Gets a list of stage positions


    
    

for i=1:num_p
    if ismember(i, stage_positions) == 1
       %fill struct with data if this stageposition has tracks
       temp = data_matrix(data_matrix(:, 6) == i,:);
       %get all data with at the current stage positions
       data_struct(i).coord = temp(:, 1:5);
       data_struct(i).num_kin = max(temp(:, 5));
       data_struct(i).timepoints = timepoints(:, i);
       data_struct(i).feat_name = objtxt(objdata(2, :) == i);
       %Fills up struct with data for tracking
       data_struct(i).datatype = 2;
       if intcheck == 1
           data_struct(i).intensities = intdata(intdata(:,size(intdata,2))...
               == i, 1:size(intdata,2)-1);
       end
    else
        data_struct(i).coord = [];
        
        data_struct(i).num_kin = 0;
        data_struct(i).timepoints = timepoints(:,i);
        data_struct(i).datatype = 2;
        %fills empty stage positions
    end
    
end

ind = 0;

for i = 1:numel(data_struct)
    struct = data_struct(i);
    
    coord = struct.coord;
    for j = 1:struct.num_kin
        
        ind = ind + 1;
        
        
        
        [r,c] = find( coord(:,5) == j);
        
        obj_struct(ind).x = coord(r, 1);
        obj_struct(ind).y = coord(r, 2);
        obj_struct(ind).z = coord(r, 3);
        obj_struct(ind).t = coord(r, 4);
        obj_struct(ind).p = i;
        if intcheck == 1
        obj_struct(ind).intensities = struct.intensities(r,:);
        end
        obj_struct(ind).time = struct.timepoints(obj_struct(ind).t);
        obj_struct(ind).objname = struct.feat_name(1,j);
        time_column = [time_column; obj_struct(ind).time]; 
    
    end
end

data_matrix = [data_matrix time_column];

if intcheck == 1

data_matrix = [data_matrix intdata];

end



