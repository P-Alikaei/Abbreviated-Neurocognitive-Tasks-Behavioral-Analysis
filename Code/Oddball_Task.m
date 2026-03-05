clc;
clear;
close all;

N_participants= 65; % Number of expected Participants


%% Loading Oddball Data

load("All_Oddball_Data.mat")

% Remove empty rows
ODDBALL_Data = All_Oddball_Data(~cellfun('isempty', All_Oddball_Data(:, 1)), :);

%% Delete repeated columns based on their time stamps

for i=1:size(ODDBALL_Data,1)
    % stimulus columns
    
    % numericRowIndex = find(all(cellfun(@(x) ~isnan(str2double(x)), PVT_Data{i, 2}.time_series), 2));
    for j=1:size(ODDBALL_Data{i, 2}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), ODDBALL_Data{i, 2}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(ODDBALL_Data{i, 2}.time_series(numericRowIndex,:), 'stable');
    ODDBALL_Data{i, 2}.time_series = ODDBALL_Data{i, 2}.time_series(:, uniqueIdx);
    ODDBALL_Data{i, 2}.time_stamps = ODDBALL_Data{i, 2}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];

    % Marker columns
    for j=1:size(ODDBALL_Data{i, 3}.time_series,1)
        numericCounts(j) = sum(cellfun(@(x) ~isnan(str2double(x)), ODDBALL_Data{i, 3}.time_series(j, :)));
    end
    [~,numericRowIndex] = max(numericCounts);
    [~, uniqueIdx] = unique(ODDBALL_Data{i, 3}.time_series(numericRowIndex,:), 'stable');
    ODDBALL_Data{i, 3}.time_series = ODDBALL_Data{i, 3}.time_series(:, uniqueIdx);
    ODDBALL_Data{i, 3}.time_stamps = ODDBALL_Data{i, 3}.time_stamps(:, uniqueIdx);
    uniqueIdx = [];
    numericCounts = [];
end


%% Number of TARGETs and STANDARDs in Stimulus Data

Count = zeros(size(ODDBALL_Data,1),5);

for i=1:size(ODDBALL_Data,1)
    Temp = ODDBALL_Data{i,2}.time_series;
    for col = 1:size(Temp, 2)-1
        if strcmp(Temp(3, col), 'SHOW') || strcmp(Temp(2, col), 'SHOW')
            if strcmp(Temp(1, col), 'TARGET')
                % 1st Column: # of TARGETs
                Count(i,1) = Count(i,1) +1;
            elseif strcmp(Temp(1, col), 'STANDARD')
                % 2nd Column: # of STANDARDs
                Count(i,2) = Count(i,2) +1;
            end
        elseif strcmp(Temp(3, col), 'HIDE') || strcmp(Temp(2, col), 'HIDE')
            if strcmp(Temp(1, col), 'TARGET')
                % 3rd Column: # of TARGETs
                Count(i,3) = Count(i,3) +1;
            elseif strcmp(Temp(1, col), 'STANDARD')
                % 4th Column: # of STANDARDs
                Count(i,4) = Count(i,4) +1;
            end
        end
    end
    % 5th Column: Total # of Stimulus
    Count(i,5) = Count(i,1) + Count(i,2);
    clear Temp
end

Count = vertcat({'# of TARGETs in SHOW','# of STANDARD in SHOW','# of TARGETs in HIDE', ...
    '# of STANDARDs in HIDE','# of Samples'},num2cell(Count));



%% Sorting ODDBALL Data

sorted_combined_data = cell(size(ODDBALL_Data,1),1);

for i=1:size(ODDBALL_Data,1)

    padding = cell(size([ODDBALL_Data{i,2}.time_series ; num2cell(ODDBALL_Data{i,2}.time_stamps)], 1)...
        -size([ODDBALL_Data{i,3}.time_series ; num2cell(ODDBALL_Data{i,3}.time_stamps)], 1), ...
        size(ODDBALL_Data{i,3}.time_series, 2));
    padding(:) = {'USER'};
    combined_data{i,1} = [[ODDBALL_Data{i,2}.time_series ; num2cell(ODDBALL_Data{i,2}.time_stamps)],...
        [ODDBALL_Data{i,3}.time_series ; padding ; num2cell(ODDBALL_Data{i,3}.time_stamps)]];
  
    % Sort Data based on time samples of data
    % [~, sorted_indices] = sort(str2double(combined_data{i,1}(2, :)));

    % Sort Data based on time stamps of system
    [~, sorted_indices] = sort(cell2mat(combined_data{i,1}(4, :)));
    sorted_combined_data{i,1} = combined_data{i,1}(:, sorted_indices);

    clear padding sorted_indices

end


%% Delete HIDE column

for i=1:size(sorted_combined_data,1)
    Temp=sorted_combined_data{i,1};
    colsToDelete = any(strcmp(Temp, 'HIDE'), 1);
    Temp(:, colsToDelete) = [];
    Data{i,1}=Temp;
    clear Temp colsToDelete
end


%% Counting Number of Mismatchs

% Initialize counter for mismatches

BehavioralCount = zeros(size(Data,1),18);

TargetRespCount = zeros(size(Data,1),1);
StandardRespCount = zeros(size(Data,1),1);

for i=1:size(Data,1)

    Temp = Data{i,1};

    for col = 1:size(Temp, 2)-1
        % Check if the current column is 'SHOW'
        if strcmp(Temp(3, col), 'SHOW') || strcmp(Temp(2, col), 'SHOW')
            % Check if the next column is 'USER'
            if strcmp(Temp(3, col+1), 'USER')
                if strcmp(Temp(1, col), 'TARGET')
                    if strcmp(Temp(1, col), Temp(1, col+1))
                        TargetRespCount(i,1) = TargetRespCount(i,1) +1;
                        TargetRespTime(i, TargetRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false TARGETs
                        BehavioralCount(i,1) = BehavioralCount(i,1)+1;

                    end
                elseif strcmp(Temp(1, col), 'STANDARD')
                    if strcmp(Temp(1, col), Temp(1, col+1))
                        StandardRespCount(i,1) = StandardRespCount(i,1) +1;
                        StandardRespTime(i, StandardRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false STANDARDs
                        BehavioralCount(i,2) = BehavioralCount(i,2)+1;

                    end
                end

            elseif strcmp(Temp(3, col+1), 'SHOW') || strcmp(Temp(2, col+1), 'SHOW')
                if strcmp(Temp(1, col), 'TARGET')
                    % # of Missed TARGETs
                    BehavioralCount(i,3) = BehavioralCount(i,3)+1;

                elseif strcmp(Temp(1, col), 'STANDARD')
                    % # of Missed STANDARDs
                    BehavioralCount(i,4) = BehavioralCount(i,4)+1;

                end
            else
                disp(['Subject index ', num2str(i), ' column ', num2str(col), ' has no correct, missed or false answer'])
            end
        end
    end

    clear Temp

end

for i=1:size(Data,1)
    % TARGET Response Time Avg
    BehavioralCount(i,5) = sum(TargetRespTime(i,:))/TargetRespCount(i,1);
    % TARGET Response Time Std
    BehavioralCount(i,6) = std(TargetRespTime(i, TargetRespTime(i, :) ~= 0));
    % STANDARD Response Time Avg
    BehavioralCount(i,7) = sum(StandardRespTime(i,:))/StandardRespCount(i,1);
    % STANDARD Response Time Std
    BehavioralCount(i,8) = std(StandardRespTime(i, StandardRespTime(i, :) ~= 0)) ;
end

%% Beavioral Responses Accuracy

Accuracy(:,1)= TargetRespCount./ cell2mat(Count(2:end,1))*100;
Accuracy(:,2) = StandardRespCount./ cell2mat(Count(2:end,2))*100;

idx = Accuracy(:,1) <= 85 | Accuracy(:,2) <= 85;

BehavioralCount(idx,:) = [];
StandardRespCount(idx,:) = [];
StandardRespTime(idx,:) = [];
TargetRespCount(idx,:) = [];
TargetRespTime(idx,:) = [];
Count(idx,:) = [];
ODDBALL_Data(idx,:) = [];
Accuracy(idx,:) = [];

%% Ploting Boxplot

RT_Target_Oddball = BehavioralCount(:,5)*1000;
RT_Standard_Oddball = BehavioralCount(:,7)*1000;

data = [RT_Target_Oddball(:); RT_Standard_Oddball(:)];
group = [repmat({'Target'}, length(RT_Target_Oddball), 1); ...
         repmat({'Standard'}, length(RT_Standard_Oddball), 1)];

colors = [1 0.6 0.8; 1 0.5 0];  


% Remove NaNs
validIdx = ~isnan(data);
data  = data(validIdx);
group = group(validIdx);


figure('Color','w','Position',[100 100 700 400]);
fancyBoxplotColoredLines(data, group, colors);

ylabel('Reaction Time (ms)','FontSize',12,'FontWeight','bold');
xlabel('Stimulus Type','FontSize',12,'FontWeight','bold');
title('Flanker Task','FontSize',14,'FontWeight','bold');

ax = gca;
ax.YLim = [300 max(data)+50];
ax.YTick = 300:100:(max(data)+50);

pbaspect([4 3 2]);



%% Preparation for Statistical Analysis in Excel

% Build RT matrix (subjects × conditions)
RT = [RT_Target_Oddball ...
      RT_Standard_Oddball];

% Checking how many subject were deleted
fprintf('# of removed subjects because of NaN values: %d subjects\n\n', sum(any(isnan(RT),2)));

% Remove subjects with any NaN
RT(any(isnan(RT),2), :) = [];
fprintf('Final sample size after removing NaNs: %d subjects\n\n', size(RT,1));

save('Oddball_StatData', 'RT')

%% Generating Data for ICC Analysis

% Assuming TargetRespTime, TargetRespCount, StandardRespTime, StandardRespCount exist

[numRows, ~] = size(TargetRespTime);

% Try to load existing split indices from file
if isfile('Oddball_split_indices.mat')
    load('Oddball_split_indices.mat', 'Oddball_split_indices_target', 'Oddball_split_indices_standard', 'Oddball_split_choice_Overall');
else
    Oddball_split_indices_target = cell(numRows, 1);
    Oddball_split_indices_standard = cell(numRows, 1);
    Oddball_split_choice_Overall = cell(numRows, 1);
end

% Output matrix for Target data: columns -> Mean_Half1, Var_Half1, Std_Half1, Mean_Half2, Var_Half2, Std_Half2
results_target = zeros(numRows, 6);

% Output matrix for Standard data
results_standard = zeros(numRows, 6);

for i = 1:numRows
    % Extract Target data without padding zeros
    count_t = TargetRespCount(i);
    data_t = TargetRespTime(i, 1:count_t);

    % Extract Standard data without padding zeros
    count_s = StandardRespCount(i);
    data_s = StandardRespTime(i, 1:count_s);

    % Generate random indices for Target data if not already generated
    if isempty(Oddball_split_indices_target{i})
        Oddball_split_indices_target{i} = randperm(count_t);
    end
    idx_t = Oddball_split_indices_target{i};

    % Generate random indices for Standard data if not already generated
    if isempty(Oddball_split_indices_standard{i})
        Oddball_split_indices_standard{i} = randperm(count_s);
    end
    idx_s = Oddball_split_indices_standard{i};

    % Split Target data into two halves
    half1_t = data_t(idx_t(1:floor(count_t/2)));
    half2_t = data_t(idx_t(floor(count_t/2)+1:end));

    results_target(i, :) = [mean(half1_t), var(half1_t), std(half1_t), mean(half2_t), var(half2_t), std(half2_t)];

    % Split Standard data into two halves
    half1_s = data_s(idx_s(1:floor(count_s/2)));
    half2_s = data_s(idx_s(floor(count_s/2)+1:end));

    results_standard(i, :) = [mean(half1_s), var(half1_s), std(half1_s), mean(half2_s), var(half2_s), std(half2_s)];

    % Split Overall data into two halves

        % Create per-row reproducible choice indices (1 or 2) if not already generated
    
    if isempty(Oddball_split_choice_Overall{i})
            % one random choice per condition: Cong, Incong, Neut
        Oddball_split_choice_Overall{i} = randi(2, 1, 2);   % [tChoice sChoice] each in {1,2}
    end
    choice = Oddball_split_choice_Overall{i};

        % Select halves for Overall-half1 and use complementary halves for Overall-half2

    if choice(1) == 1
        pick1_t = half1_t;  pick2_t = half2_t;
    else
        pick1_t = half2_t;  pick2_t = half1_t;
    end

    if choice(2) == 1
        pick1_s = half1_s;  pick2_s = half2_s;
    else
        pick1_s = half2_s;  pick2_s = half1_s;
    end


        % Build Overall halves by combining the selected halves from each condition
    half1_O = [pick1_t(:); pick1_s(:)];
    half2_O = [pick2_t(:); pick2_s(:)];

    results_Overall(i, :) = [mean(half1_O), var(half1_O), std(half1_O), mean(half2_O), var(half2_O), std(half2_O)];

end

% Save the split indices for both Target and Standard data
save('Oddball_split_indices.mat', 'Oddball_split_indices_target', 'Oddball_split_indices_standard', 'Oddball_split_choice_Overall');

% Save results for SPSS
save('Oddball_ICCData', 'results_standard', 'results_target', 'results_Overall')

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

