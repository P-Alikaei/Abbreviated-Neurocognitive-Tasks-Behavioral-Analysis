% Note: This script is parameterizable across conditions and trials.
% Although currently configured for ZeroBack Trial 1 (All_ZeroBack1_Data.mat),
% it can be applied to other datasets by modifying the input file name
% and corresponding variable names.

% The output of this script is used as input for the n_Back_Task.m script.

clc;
clear;
close all;


N_participants= 65; % Number of expected Participants


%% Loading nBack Data

load('All_ZeroBack1_Data.mat');

% Remove empty rows
ZeroBack1_Data = All_ZeroBack1_Data(~cellfun('isempty', All_ZeroBack1_Data(:, 1)), :);

%% Remove empty Stimulus or Marker Time series

j = zeros(size(ZeroBack1_Data,1), 2);
for i=1:size(ZeroBack1_Data,1)
    % check stimulus
    if isempty(ZeroBack1_Data{i, 2}.time_series)
        disp(['Subject', num2str(ZeroBack1_Data{i, 1}), ' has an empty Stimulus data']);
        j(i,1)=i;
    end
    % check Marker
    if isempty(ZeroBack1_Data{i, 3}.time_series)
        disp(['Subject', num2str(ZeroBack1_Data{i, 1}), ' has an empty marker data']);
        j(i,2)=i;
    end
end

for i=1:size(ZeroBack1_Data,1)
    ZeroBack1_Data(nonzeros(j(i,:)),:) = [];
end


%% reorganize data to put SHOW and HIDE in third row of Stimulus data

for i=1:size(ZeroBack1_Data,1)
    [Indices{i},~] = find(strcmp(ZeroBack1_Data{i, 2}.time_series,'SHOW'));

    if  unique(Indices{i}) ~=3
        disp(['subject', num2str(ZeroBack1_Data{i, 1}), ' in not organized as standard format'])
        Temp = ZeroBack1_Data{i, 2}.time_series(2,:);
        ZeroBack1_Data{i, 2}.time_series(2,:) = ZeroBack1_Data{i, 2}.time_series(3,:);
        ZeroBack1_Data{i, 2}.time_series(3,:) = Temp;
    end
    Temp = [];
end


%% Delete repeated columns based on their time stamps

for i=1:size(ZeroBack1_Data,1)
    % stimulus columns
    
    % numericRowIndex = find(all(cellfun(@(x) ~isnan(str2double(x)), PVT_Data{i, 2}.time_series), 2));
    for j=1:size(ZeroBack1_Data{i, 2}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), ZeroBack1_Data{i, 2}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(ZeroBack1_Data{i, 2}.time_series(numericRowIndex,:), 'stable');
    ZeroBack1_Data{i, 2}.time_series = ZeroBack1_Data{i, 2}.time_series(:, uniqueIdx);
    ZeroBack1_Data{i, 2}.time_stamps = ZeroBack1_Data{i, 2}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];

    % Marker columns
    for j=1:size(ZeroBack1_Data{i, 3}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), ZeroBack1_Data{i, 3}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(ZeroBack1_Data{i, 3}.time_series(numericRowIndex,:), 'stable');
    ZeroBack1_Data{i, 3}.time_series = ZeroBack1_Data{i, 3}.time_series(:, uniqueIdx);
    ZeroBack1_Data{i, 3}.time_stamps = ZeroBack1_Data{i, 3}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];
end


%% Sorting ZeroBack Data

sorted_combined_data = cell(size(ZeroBack1_Data,1),1);

for i=1:size(ZeroBack1_Data,1)
    padding = cell(size([ZeroBack1_Data{i,2}.time_series ; num2cell(ZeroBack1_Data{i,2}.time_stamps)], 1)...
        -size([ZeroBack1_Data{i,3}.time_series ; num2cell(ZeroBack1_Data{i,3}.time_stamps)], 1), ...
        size(ZeroBack1_Data{i,3}.time_series, 2));
    padding(:) = {'USER'};
    combined_data{i,1} = [[ZeroBack1_Data{i,2}.time_series ; num2cell(ZeroBack1_Data{i,2}.time_stamps)],...
        [ZeroBack1_Data{i,3}.time_series ; padding ; num2cell(ZeroBack1_Data{i,3}.time_stamps)]];
    [~, sorted_indices] = sort(cell2mat(combined_data{i,1}(4, :)));
    sorted_combined_data{i,1} = combined_data{i,1}(:, sorted_indices);

    clear sorted_indices padding

end

%% Delete HIDE column

for i=1:size(sorted_combined_data,1)
    Temp=sorted_combined_data{i,1};
    colsToDelete = any(strcmp(Temp, 'HIDE'), 1);
    Temp(:, colsToDelete) = [];
    Data{i,1}=Temp;
    clear Temp colsToDelete
end


%% Number of TARGETs and STANDARDs in Stimulus Data

Count = zeros(size(Data,1),3);

for i=1:size(Data,1)
    Temp = Data{i,1};
    for col = 1:size(Temp, 2)
        if contains(Temp(3, col), 'SHOW')
            % 3th Column: Total # of Stimulus
            Count(i,3) = Count(i,3) +1;
            if contains(Temp(1, col), 'TARGET')
                % 1st Column: # of TARGETs
                Count(i,1) = Count(i,1) +1;
            elseif contains(Temp(1, col), 'STANDARD')
                % 2nd Column: # of STANDARDs
                Count(i,2) = Count(i,2) +1;
            end
        end
    end
    clear Temp
end

Count = vertcat({'# of shown TARGETs','# of shown STANDARDs', 'Total # of Stimuli'},num2cell(Count));

%% Counting Number of Mistakes


BehavioralCount = zeros(size(Data,1),12);
TargetRespTime = zeros(size(Data,1),max(cell2mat(Count(2:end,1))));
StandardRespTime = zeros(size(Data,1),max(cell2mat(Count(2:end,2))));

for i=1:size(ZeroBack1_Data,1)
    % select Stimulus Data
    Temp = [];
    Temp = Data{i,1};
    TargetRespCount(i,1) = 0;
    StandardRespCount(i,1) = 0;

    for col = 1:size(Temp,2)-1
        if contains(Temp(3, col), 'SHOW') && contains(Temp(1, col), 'Status')
            if contains(Temp(3, col+1), 'USER')
                if contains(Temp(1, col), Temp(1, col+1))
                    if contains(Temp(1, col), 'TARGET')
                        TargetRespCount(i,1) = TargetRespCount(i,1) +1;
                        TargetRespTime(i, TargetRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};

                    elseif contains(Temp(1, col), 'STANDARD')
                        StandardRespCount(i,1) = StandardRespCount(i,1) +1;
                        StandardRespTime(i, StandardRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};

                    end
                else
                    if contains(Temp(1, col), 'TARGET')
                        % # of False Answers for TARGET
                        BehavioralCount(i,1) = BehavioralCount(i,1) +1;

                    elseif contains(Temp(1, col), 'STANDARD')
                        % # of False Answers for STANDARD
                        BehavioralCount(i,2) = BehavioralCount(i,2) +1;
                    end
                end
            elseif contains(Temp(3, col+1), 'SHOW') && contains(Temp(1, col+1), 'Status')
                if contains(Temp(1, col), 'TARGET')
                    % # of Missed Targets
                    BehavioralCount(i,3) = BehavioralCount(i,3) +1;

                elseif contains(Temp(1, col), 'STANDARD')
                    % # of Missed STANDARDs
                    BehavioralCount(i,4) = BehavioralCount(i,4) +1;

                end
            else
                disp(['Subject index ', num2str(i), ' column ', num2str(col), ' has no correct, missed or false answer'])
                if contains(Temp(1, col), 'TARGET')
                    % # of App issues for TARGET
                    BehavioralCount(i,5) = BehavioralCount(i,5) +1;

                elseif contains(Temp(1, col), 'STANDARD')
                    % # of App issues for TARGET
                    BehavioralCount(i,6) = BehavioralCount(i,6) +1;

                end
            end
        end
    end
end



for i=1:size(Data,1)
    % TARGETs Response Time Avg
    BehavioralCount(i,7) = sum(TargetRespTime(i,:))/TargetRespCount(i,1);
    % TARGETs Response Time Std
    BehavioralCount(i,8) = std(TargetRespTime(i, TargetRespTime(i, :) ~= 0));
    % STANDARDs Response Time Avg
    BehavioralCount(i,9) = sum(StandardRespTime(i,:))/StandardRespCount(i,1);
    % STANDARDs Response Time Std
    BehavioralCount(i,10) = std(StandardRespTime(i, StandardRespTime(i, :) ~= 0)) ;
end



%% save data for overal Zero back analysis

Count1 = Count1(:,1);
TargetRespTime1 = TargetRespTime;
TargetRespCount1 = TargetRespCount;
StandardRespTime1 = StandardRespTime;
StandardRespCount1 = StandardRespCount;
BehavioralCount1 = BehavioralCount;
Count_1=Count;

save('ZeroBack1_Data.mat', 'Count1', 'TargetRespTime1','TargetRespCount1','StandardRespTime1','StandardRespCount1','BehavioralCount1','Count_1')