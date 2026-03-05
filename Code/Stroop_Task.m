clc;
clear;
close all;

N_participants= 65; % Number of expected Participants

%% Loading Stroop Data

load("All_Stroop_Data.mat")

% Remove empty rows
Stroop_Data = All_Stroop_Data(~cellfun('isempty', All_Stroop_Data(:, 1)), :);

%% Remove empty Stimulus or Marker Time series

j = zeros(size(Stroop_Data,1), 2);
for i=1:size(Stroop_Data,1)
    % check stimulus
    if isempty(Stroop_Data{i, 2}.time_series)
        disp(['Subject', num2str(Stroop_Data{i, 1}), ' has an empty Stimulus data']);
        j(i,1)=i;
    end
    % check Marker
    if isempty(Stroop_Data{i, 3}.time_series)
        disp(['Subject', num2str(Stroop_Data{i, 1}), ' has an empty marker data']);
        j(i,2)=i;
    end
end

for i=1:size(Stroop_Data,1)
    Stroop_Data(nonzeros(j(i,:)),:) = [];
end


%% reorganize data to put SHOW and HIDE in third row of Stimulus data

for i=1:size(Stroop_Data,1)
    [Indices{i},~] = find(strcmp(Stroop_Data{i, 2}.time_series,'SHOW'));

    if  unique(Indices{i}) ~=3
        disp(['subject', num2str(Stroop_Data{i, 1}), ' in not organized as standard format'])
        Temp = Stroop_Data{i, 2}.time_series(2,:);
        Stroop_Data{i, 2}.time_series(2,:) = Stroop_Data{i, 2}.time_series(3,:);
        Stroop_Data{i, 2}.time_series(3,:) = Temp;
    end
    Temp = [];
end


%% Delete repeated columns based on their time stamps

for i=1:size(Stroop_Data,1)
    % stimulus columns
    
    % numericRowIndex = find(all(cellfun(@(x) ~isnan(str2double(x)), PVT_Data{i, 2}.time_series), 2));
    for j=1:size(Stroop_Data{i, 2}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), Stroop_Data{i, 2}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(Stroop_Data{i, 2}.time_series(numericRowIndex,:), 'stable');
    Stroop_Data{i, 2}.time_series = Stroop_Data{i, 2}.time_series(:, uniqueIdx);
    Stroop_Data{i, 2}.time_stamps = Stroop_Data{i, 2}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];

    % Marker columns
    for j=1:size(Stroop_Data{i, 3}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), Stroop_Data{i, 3}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(Stroop_Data{i, 3}.time_series(numericRowIndex,:), 'stable');
    Stroop_Data{i, 3}.time_series = Stroop_Data{i, 3}.time_series(:, uniqueIdx);
    Stroop_Data{i, 3}.time_stamps = Stroop_Data{i, 3}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];
end


%% Sorting Bluegrass Data

sorted_combined_data = cell(size(Stroop_Data,1),1);

for i=1:size(Stroop_Data,1)
    padding = cell(size([Stroop_Data{i,2}.time_series ; num2cell(Stroop_Data{i,2}.time_stamps)], 1)...
        -size([Stroop_Data{i,3}.time_series ; num2cell(Stroop_Data{i,3}.time_stamps)], 1), ...
        size(Stroop_Data{i,3}.time_series, 2));
    padding(:) = {'USER'};
    combined_data{i,1} = [[Stroop_Data{i,2}.time_series ; num2cell(Stroop_Data{i,2}.time_stamps)],...
        [Stroop_Data{i,3}.time_series ; padding ; num2cell(Stroop_Data{i,3}.time_stamps)]];
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


%% Number of shown stimulus

Count = zeros(size(Stroop_Data,1),3);

for i=1:size(Stroop_Data,1)
    Temp = Stroop_Data{i,2}.time_series;
    for col = 1:size(Temp, 2)-1
        if contains(Temp(3, col), 'SHOW')
            Count(i,3) = Count(i,3) +1;
            parts{i,col} = split(Temp(1,col), '_');
            if strcmp(parts{i,col}{1,1},parts{i,col}{2,1})
                % # of Congruents
                Count(i,1) = Count(i,1) +1;
            elseif ~strcmp(parts{i,col}{1,1},parts{i,col}{2,1})
                % # of InCongruents
                Count(i,2) = Count(i,2) +1;
            end
        end
    end
end

Count = vertcat({'# of Cong in SHOW','# of Incong in SHOW','Total # of Stimuli'},num2cell(Count));

%% Counting Number of Mismatchs

BehavioralCount = zeros(size(Data,1),18);

CongRespCount = zeros(size(Data,1),1);
IncongRespCount = zeros(size(Data,1),1);

parts = [];
for i=1:size(Data,1)
    Temp = Data{i,1};
    for col = 1:size(Temp, 2)-1
        if contains(Temp(3, col), 'SHOW')
            parts{i,col} = split(Temp(1,col), '_');
            if contains(Temp(3, col+1), 'USER')
                if contains(parts{i,col}{1,1},parts{i,col}{2,1})
                    if contains(parts{i,col}{2,1},Temp(1, col+1))
                        CongRespCount(i,1) = CongRespCount(i,1) +1;
                        CongRespTime(i, CongRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false Cong
                        BehavioralCount(i,1) = BehavioralCount(i,1)+1;

                    end
                else
                    if contains(parts{i,col}{2,1},Temp(1, col+1))
                        IncongRespCount(i,1) = IncongRespCount(i,1) +1;
                        IncongRespTime(i, IncongRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false Incong
                        BehavioralCount(i,2) = BehavioralCount(i,2)+1;

                    end
                end

            elseif contains(Temp(3, col+1), 'SHOW')
                if contains(parts{i,col}{1,1},parts{i,col}{2,1})
                    % # of missed Cong
                    BehavioralCount(i,3) = BehavioralCount(i,3)+1;

                elseif ~contains(parts{i,col}{1,1},parts{i,col}{2,1})
                    % # of missed Incong
                    BehavioralCount(i,4) = BehavioralCount(i,4)+1;

                end
            else
                disp(['Subject index ', num2str(i), ' column ', num2str(col), ' has no correct, missed or false answer'])
            end
        end
    end
end


for i=1:size(Data,1)
    % CONGRUENT Response Time Avg
    BehavioralCount(i,5) = sum(CongRespTime(i,:))/CongRespCount(i,1);
    % CONGRUENT Response Time Std
    BehavioralCount(i,6) = std(CongRespTime(i, CongRespTime(i, :) ~= 0));
    % INCONGRUENT Response Time Avg
    BehavioralCount(i,7) = sum(IncongRespTime(i,:))/IncongRespCount(i,1);
    % INCONGRUENT Response Time Std
    BehavioralCount(i,8) = std(IncongRespTime(i, IncongRespTime(i, :) ~= 0)) ;
end

%% Beavioral Responses Accuracy

Accuracy(:,1)= CongRespCount./ cell2mat(Count(2:end,1))*100;
Accuracy(:,2) = IncongRespCount./ cell2mat(Count(2:end,2))*100;

idx = Accuracy(:,1) <= 85 | Accuracy(:,2) <= 85;

BehavioralCount(idx,:) = [];
CongRespCount(idx,:) = [];
CongRespTime(idx,:) = [];
IncongRespCount(idx,:) = [];
IncongRespTime(idx,:) = [];
Count(idx,:) = [];
Stroop_Data(idx,:) = [];
Accuracy(idx,:) = [];

%% Ploting Boxplot

RT_Cong_Stroop = BehavioralCount(:,5)*1000;
RT_Incong_Stroop = BehavioralCount(:,7)*1000;

data = [RT_Cong_Stroop(:); RT_Incong_Stroop(:)];
group = [repmat({'Congruent'}, length(RT_Cong_Stroop), 1); ...
         repmat({'Incongruent'}, length(RT_Incong_Stroop), 1)];

colors = [0 0.4470 0.7410; 1 0.6 0.8];

figure('Color','w','Position',[100 100 600 400]);
fancyBoxplotColoredLines(data, group, colors);

ylabel('Reaction Time (ms)','FontSize',12,'FontWeight','bold');
xlabel('Stimulus Type','FontSize',12,'FontWeight','bold');
title('Stroop Task','FontSize',14,'FontWeight','bold');

ax = gca;
ax.YLim = [300 max(data)+50];
ax.YTick = 300:200:(max(data)+50);

pbaspect([4 3 2]);

%% Preparation for Statistical Analysis in Excel

% Build RT matrix (subjects × conditions)
RT = [RT_Cong_Stroop ...
      RT_Incong_Stroop];

% Checking how many subject were deleted
fprintf('# of removed subjects because of NaN values: %d subjects\n\n', sum(any(isnan(RT),2)));

% Remove subjects with any NaN
RT(any(isnan(RT),2), :) = [];
fprintf('Final sample size after removing NaNs: %d subjects\n\n', size(RT,1));

save('Stroop_StatData', 'RT')

%% Generating Data for ICC Analysis

% Assuming TargetRespTime, TargetRespCount, StandardRespTime, StandardRespCount exist

[numRows, ~] = size(CongRespTime);

% Try to load existing split indices from file
if isfile('Stroop_split_indices.mat')
    load('Stroop_split_indices.mat', 'Stroop_split_indices_Incong', 'Stroop_split_indices_Cong', 'Stroop_split_choice_Overall');
else
    Stroop_split_indices_Incong = cell(numRows, 1);
    Stroop_split_indices_Cong = cell(numRows, 1);
    Stroop_split_choice_Overall = cell(numRows, 1);
end

% Output matrix for Target data: columns -> Mean_Half1, Var_Half1, Std_Half1, Mean_Half2, Var_Half2, Std_Half2
results_Incong = zeros(numRows, 6);

% Output matrix for Standard data
results_Cong = zeros(numRows, 6);

for i = 1:numRows
    % Extract Incong data without padding zeros
    count_i = IncongRespCount(i);
    data_i = IncongRespTime(i, 1:count_i);

    % Extract Cong data without padding zeros
    count_c = CongRespCount(i);
    data_c = CongRespTime(i, 1:count_c);

    % Generate random indices for Incong data if not already generated
    if isempty(Stroop_split_indices_Incong{i})
        Stroop_split_indices_Incong{i} = randperm(count_i);
    end
    idx_i = Stroop_split_indices_Incong{i};

    % Generate random indices for Standard data if not already generated
    if isempty(Stroop_split_indices_Cong{i})
        Stroop_split_indices_Cong{i} = randperm(count_c);
    end
    idx_c = Stroop_split_indices_Cong{i};

    % Split Target data into two halves
    half1_i = data_i(idx_i(1:floor(count_i/2)));
    half2_i = data_i(idx_i(floor(count_i/2)+1:end));

    results_Incong(i, :) = [mean(half1_i), var(half1_i), std(half1_i), mean(half2_i), var(half2_i), std(half2_i)];

    % Split Standard data into two halves
    half1_c = data_c(idx_c(1:floor(count_c/2)));
    half2_c = data_c(idx_c(floor(count_c/2)+1:end));

    results_Cong(i, :) = [mean(half1_c), var(half1_c), std(half1_c), mean(half2_c), var(half2_c), std(half2_c)];

    % Split Overall data into two halves

        % Create per-row reproducible choice indices (1 or 2) if not already generated
    
    if isempty(Stroop_split_choice_Overall{i})
            % one random choice per condition: Cong, Incong, Neut
        Stroop_split_choice_Overall{i} = randi(2, 1, 2);   % [tChoice sChoice] each in {1,2}
    end
    choice = Stroop_split_choice_Overall{i};

        % Select halves for Overall-half1 and use complementary halves for Overall-half2

    if choice(1) == 1
        pick1_t = half1_i;  pick2_t = half2_i;
    else
        pick1_t = half2_i;  pick2_t = half1_i;
    end

    if choice(2) == 1
        pick1_s = half1_c;  pick2_s = half2_c;
    else
        pick1_s = half2_c;  pick2_s = half1_c;
    end


        % Build Overall halves by combining the selected halves from each condition
    half1_O = [pick1_t(:); pick1_s(:)];
    half2_O = [pick2_t(:); pick2_s(:)];

    results_Overall(i, :) = [mean(half1_O), var(half1_O), std(half1_O), mean(half2_O), var(half2_O), std(half2_O)];
end

% Save the split indices for both Target and Standard data
save('Stroop_split_indices.mat', 'Stroop_split_indices_Incong', 'Stroop_split_indices_Cong', 'Stroop_split_choice_Overall');

% Save results for SPSS
save('Stroop_ICCData', 'results_Cong', 'results_Incong', 'results_Overall')

%% Helper function

% Colored boxplot with whiskers same color

function fancyBoxplotColoredLines(data, group, colors)
    nGroups = numel(unique(group));

    h = boxplot(data, group, 'Notch','on','Whisker',1.5, 'Symbol','');

    boxes = findobj(h,'Tag','Box');
    medians = findobj(h,'Tag','Median');
    whiskers = findobj(h,'Tag','Whisker');
    caps = findobj(h,'Tag','Upper Adjacent Value');
    lowerCaps = findobj(h,'Tag','Lower Adjacent Value');

    for j = 1:length(boxes)
        set(boxes(j), 'Color', colors(j,:), 'LineWidth',2)
    end
    for j = 1:length(medians)
        set(medians(j), 'Color', colors(j,:), 'LineWidth',2)
    end
    for j = 1:length(whiskers)
        idx = mod(j-1, nGroups)+1;
        set(whiskers(j), 'Color', colors(idx,:), 'LineWidth',1.8)
    end
    for j = 1:length(caps)
        idx = mod(j-1, nGroups)+1;
        set(caps(j),'Color', colors(idx,:), 'LineWidth',1.8)
    end
    for j = 1:length(lowerCaps)
        idx = mod(j-1, nGroups)+1;
        set(lowerCaps(j),'Color', colors(idx,:), 'LineWidth',1.8)
    end

    for j = 1:length(boxes)
        
        idx = mod(j-1, nGroups)+1;
        patch(get(boxes(j),'XData'), get(boxes(j),'YData'), colors(idx,:), ...
            'FaceAlpha',0.3, ...       %  transparency 0.3
            'EdgeColor','none');       % without additional edge
    end

    grid on
    set(gca,'LineWidth',1.2,'FontSize',12)
end

