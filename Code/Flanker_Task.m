clc;
clear;
close all;

N_participants= 65; % Number of expected Participants


%% Loading Flanker Data

load("All_Flanker_Data.mat")

% Remove empty rows
Flanker_Data = All_Flanker_Data(~cellfun('isempty', All_Flanker_Data(:, 1)), :);

%% Remove empty Stimulus or Marker Time series

j = zeros(size(Flanker_Data,1), 2);
for i=1:size(Flanker_Data,1)
    % check stimulus
    if isempty(Flanker_Data{i, 2}.time_series)
        disp(['Subject', num2str(Flanker_Data{i, 1}), ' has an empty Stimulus data']);
        j(i,1)=i;
    end
    % check Marker
    if isempty(Flanker_Data{i, 3}.time_series)
        disp(['Subject', num2str(Flanker_Data{i, 1}), ' has an empty marker data']);
        j(i,2)=i;
    end
end

for i=1:size(Flanker_Data,1)
    Flanker_Data(nonzeros(j(i,:)),:) = [];
end


%% Reorganize Data

for i=1:size(Flanker_Data,1)
    [Indices{i},~] = find(strcmp(Flanker_Data{i, 2}.time_series,'SHOW'));

    if  unique(Indices{i}) ~=3
        disp(['subject', num2str(Flanker_Data{i, 1}), ' in not organized as standard format'])
        Temp = Flanker_Data{i, 2}.time_series(2,:);
        Flanker_Data{i, 2}.time_series(2,:) = Flanker_Data{i, 2}.time_series(3,:);
        Flanker_Data{i, 2}.time_series(3,:) = Temp;
    end
    Temp = [];
end


%% Delete repeated columns based on their time stamps

for i=1:size(Flanker_Data,1)
    % stimulus columns
    uniqueIdx = [];
    [~, uniqueIdx] = unique(Flanker_Data{i, 2}.time_series(2,:), 'stable');
    Flanker_Data{i, 2}.time_series = Flanker_Data{i, 2}.time_series(:, uniqueIdx);
    Flanker_Data{i, 2}.time_stamps = Flanker_Data{i, 2}.time_stamps(:, uniqueIdx);

    % Marker columns
    uniqueIdx = [];
    [~, uniqueIdx] = unique(Flanker_Data{i, 3}.time_series(2,:), 'stable');
    Flanker_Data{i, 3}.time_series = Flanker_Data{i, 3}.time_series(:, uniqueIdx);
    Flanker_Data{i, 3}.time_stamps = Flanker_Data{i, 3}.time_stamps(:, uniqueIdx);
end

%% Sort Data

sorted_combined_data = cell(size(Flanker_Data,1),1);

for i=1:size(Flanker_Data,1)
    padding = cell(size([Flanker_Data{i,2}.time_series ; num2cell(Flanker_Data{i,2}.time_stamps)], 1)...
        -size([Flanker_Data{i,3}.time_series ; num2cell(Flanker_Data{i,3}.time_stamps)], 1), ...
        size(Flanker_Data{i,3}.time_series, 2));
    padding(:) = {'USER'};
    combined_data{i,1} = [[Flanker_Data{i,2}.time_series ; num2cell(Flanker_Data{i,2}.time_stamps)],...
        [Flanker_Data{i,3}.time_series ; padding ; num2cell(Flanker_Data{i,3}.time_stamps)]];
    [~, sorted_indices] = sort(cell2mat(combined_data{i,1}(4, :)));
    sorted_combined_data{i,1} = combined_data{i,1}(:, sorted_indices);

    clear sorted_indices padding

end

for i=1:size(sorted_combined_data,1)
    Temp=sorted_combined_data{i,1};
    colsToDelete = any(strcmp(Temp, 'HIDE'), 1);
    Temp(:, colsToDelete) = [];
    Data{i,1}=Temp;
    clear Temp colsToDelete
end


%% Number of CONGRUENTs , INCONGRUENTs and NEUTRAL in Stimulus Data to be used for Accuracy calculations

Count = zeros(size(Flanker_Data,1),4);

for i=1:size(Flanker_Data,1)
    Temp = Flanker_Data{i,2}.time_series;
    for col = 1:size(Temp, 2)
        if contains(Temp(3, col), 'SHOW')
            % 4th Column: Total # of Stimulus
            Count(i,4) = Count(i,4) +1;
            if contains(Temp(1, col), 'CONGRUENT') && ~contains(Temp(1, col), 'INCONGRUENT')
                % 1st Column: # of CONGRUENT
                Count(i,1) = Count(i,1) +1;
            elseif contains(Temp(1, col), 'INCONGRUENT')
                % 2nd Column: # of INCONGRUENT
                Count(i,2) = Count(i,2) +1;
            elseif contains(Temp(1, col), 'NEUTRAL')
                % 3nd Column: # of NEUTRAL
                Count(i,3) = Count(i,3) +1;
            end
        end
    end
    % 5th Column: Total # of Stimulus
    Count(i,4) = Count(i,1) + Count(i,2) + Count(i,3);
    clear Temp
end

Count = vertcat({'# of CONGRUENTs in SHOW','# of INCONGRUENTs in SHOW','# of NEUTRAL in SHOW', ...
    'Total # of Stimulus'},num2cell(Count));

%% Counting Number of Mismatchs

% Initialize counter for mismatches

BehavioralCount = zeros(size(Data,1),18);

CongRespCount = zeros(size(Data,1),1);
IncongRespCount = zeros(size(Data,1),1);
NeuRespCount = zeros(size(Data,1),1);

for i=1:size(Data,1)

    Temp = Data{i,1};

    for col = 1:size(Temp, 2)-1
        % Check if the current column is 'SHOW'
        if contains(Temp(3, col), 'SHOW')
            % Check if the next column is 'USER'
            if contains(Temp(3, col+1), 'USER')
                if contains(Temp(1, col), 'CONGRUENT') && ~contains(Temp(1, col), 'INCONGRUENT')
                    if contains(Temp(1, col), Temp(1, col+1))
                        CongRespCount(i,1) = CongRespCount(i,1) +1;
                        CongRespTime(i, CongRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false CONGRUENT
                        BehavioralCount(i,1) = BehavioralCount(i,1)+1;

                    end
                elseif contains(Temp(1, col), 'INCONGRUENT')
                    if contains(Temp(1, col), Temp(1, col+1))
                        IncongRespCount(i,1) = IncongRespCount(i,1) +1;
                        IncongRespTime(i, IncongRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false INCONGRUENT
                        BehavioralCount(i,2) = BehavioralCount(i,2)+1;

                    end
                elseif contains(Temp(1, col), 'NEUTRAL')
                    if contains(Temp(1, col), Temp(1, col+1))
                        NeuRespCount(i,1) = NeuRespCount(i,1) +1;
                        NeuRespTime(i, NeuRespCount(i,1)) = Temp{end, col+1} - Temp{end, col};
                    else
                        % # of false NEUTRAL
                        BehavioralCount(i,3) = BehavioralCount(i,3)+1;

                    end
                end

            elseif contains(Temp(3, col+1), 'SHOW')
                if contains(Temp(1, col), 'CONGRUENT') && ~contains(Temp(1, col), 'INCONGRUENT')
                    % # of Missed CONGRUENTs
                    BehavioralCount(i,4) = BehavioralCount(i,4)+1;

                elseif contains(Temp(1, col), 'INCONGRUENT')
                    % # of Missed INCONGRUENT
                    BehavioralCount(i,5) = BehavioralCount(i,5)+1;

                elseif contains(Temp(1, col), 'NEUTRAL')
                    % # of Missed NEUTRAL
                    BehavioralCount(i,6) = BehavioralCount(i,6)+1;

                end
            end
        end
    end

    clear Temp

end

for i=1:size(Data,1)
    % CONGRUENT Response Time Avg
    BehavioralCount(i,7) = sum(CongRespTime(i,:))/CongRespCount(i,1);
    % CONGRUENT Response Time Std
    BehavioralCount(i,8) = std(CongRespTime(i, CongRespTime(i, :) ~= 0));
    % INCONGRUENT Response Time Avg
    BehavioralCount(i,9) = sum(IncongRespTime(i,:))/IncongRespCount(i,1);
    % INCONGRUENT Response Time Std
    BehavioralCount(i,10) = std(IncongRespTime(i, IncongRespTime(i, :) ~= 0)) ;
    % NEUTRAL Response Time Avg
    BehavioralCount(i,11) = sum(NeuRespTime(i,:))/NeuRespCount(i,1);
    % NEUTRAL Response Time Std
    BehavioralCount(i,12) = std(NeuRespTime(i, NeuRespTime(i, :) ~= 0)) ;
end

%% Beavioral Responses Accuracy

Accuracy(:,1)= CongRespCount./ cell2mat(Count(2:end,1))*100;
Accuracy(:,2) = IncongRespCount./ cell2mat(Count(2:end,2))*100;
Accuracy(:,3) = NeuRespCount./ cell2mat(Count(2:end,3))*100;

idx = Accuracy(:,1) <= 85 | Accuracy(:,2) <= 85;

BehavioralCount(idx,:) = [];
CongRespCount(idx,:) = [];
CongRespTime(idx,:) = [];
IncongRespCount(idx,:) = [];
IncongRespTime(idx,:) = [];
NeuRespCount(idx,:) = [];
NeuRespTime(idx,:) = [];
Count(idx,:) = [];
Flanker_Data(idx,:) = [];
Accuracy(idx,:) = [];

%% Ploting Boxplot

RT_Cong_Flanker = BehavioralCount(:,7)*1000;
RT_Incong_Flanker = BehavioralCount(:,9)*1000;
RT_Neutral_Flanker = BehavioralCount(:,11)*1000;

data = [RT_Cong_Flanker(:); RT_Incong_Flanker(:); RT_Neutral_Flanker(:)];
group = [repmat({'Congruent'}, length(RT_Cong_Flanker), 1); ...
         repmat({'Incongruent'}, length(RT_Incong_Flanker), 1); ...
         repmat({'Neutral'}, length(RT_Neutral_Flanker), 1)];

% Remove NaNs
validIdx = ~isnan(data);
data  = data(validIdx);
group = group(validIdx);


colors = [0.2 0.7 0; 1 0.85 0; 1 0.5 0];

figure('Color','w','Position',[100 100 700 400]);
fancyBoxplotColoredLines(data, group, colors);

ylabel('Reaction Time (ms)','FontSize',12,'FontWeight','bold');
xlabel('Stimulus Type','FontSize',12,'FontWeight','bold');
title('Flanker Task','FontSize',14,'FontWeight','bold');

ax = gca;
ax.YLim = [300 max(data)+50];
ax.YTick = 300:100:(max(data)+50);

pbaspect([4 3 2]);


%% Preparation for Statistical Analysis

% Build RT matrix (subjects × conditions)
RT = [RT_Cong_Flanker ...
      RT_Incong_Flanker ...
      RT_Neutral_Flanker];

% Checking how many subject were deleted
fprintf('# of removed subjects because of NaN values: %d subjects\n\n', sum(any(isnan(RT),2)));

% Remove subjects with any NaN
RT(any(isnan(RT),2), :) = [];
fprintf('Final sample size after removing NaNs: %d subjects\n\n', size(RT,1));

save('Flanker_StatData', 'RT')

%% Generating Data for ICC Analysis

% Assuming TargetRespTime, TargetRespCount, StandardRespTime, StandardRespCount exist

[numRows, ~] = size(CongRespTime);

% Try to load existing split indices from file
if isfile('Flanker_split_indices.mat')
    load('Flanker_split_indices.mat', 'Flanker_split_indices_Cong', 'Flanker_split_indices_Incong', ...
        'Flanker_split_indices_Neut', 'Flanker_split_choice_Overall');
else
    Flanker_split_indices_Cong = cell(numRows, 1);
    Flanker_split_indices_Incong = cell(numRows, 1);
    Flanker_split_indices_Neut = cell(numRows, 1);
    Flanker_split_choice_Overall = cell(numRows, 1);
end


% Output matrix: columns -> Mean_Half1, Var_Half1, Std_Half1, Mean_Half2, Var_Half2, Std_Half2
results_Cong = zeros(numRows, 6);
results_Incong = zeros(numRows, 6);
results_Neut = zeros(numRows, 6);

for i = 1:numRows
    % Extract Cong data without padding zeros
    count_c = CongRespCount(i);
    data_c = CongRespTime(i, 1:count_c);

    % Extract Incong data without padding zeros
    count_i = IncongRespCount(i);
    data_i = IncongRespTime(i, 1:count_i);

    % Extract Neutral data without padding zeros
    count_n = NeuRespCount(i);
    data_n = NeuRespTime(i, 1:count_n);

    % Generate random indices for Cong data if not already generated
    if isempty(Flanker_split_indices_Cong{i})
        Flanker_split_indices_Cong{i} = randperm(count_c);
    end
    idx_c = Flanker_split_indices_Cong{i};

    % Generate random indices for Incong data if not already generated
    if isempty(Flanker_split_indices_Incong{i})
        Flanker_split_indices_Incong{i} = randperm(count_i);
    end
    idx_i = Flanker_split_indices_Incong{i};

    % Generate random indices for Neutral data if not already generated
    
    if isempty(Flanker_split_indices_Neut{i})
        Flanker_split_indices_Neut{i} = randperm(count_n);
    end
    idx_n = Flanker_split_indices_Neut{i};

    % Split Congruent data into two halves
    half1_c = data_c(idx_c(1:floor(count_c/2)));
    half2_c = data_c(idx_c(floor(count_c/2)+1:end));

    results_Cong(i, :) = [mean(half1_c), var(half1_c), std(half1_c), mean(half2_c), var(half2_c), std(half2_c)];

    % Split Incongruent data into two halves
    half1_i = data_i(idx_i(1:floor(count_i/2)));
    half2_i = data_i(idx_i(floor(count_i/2)+1:end));

    results_Incong(i, :) = [mean(half1_i), var(half1_i), std(half1_i), mean(half2_i), var(half2_i), std(half2_i)];

    % Split Neutral data into two halves
    half1_n = data_n(idx_n(1:floor(count_n/2)));
    half2_n = data_n(idx_n(floor(count_n/2)+1:end));

    results_Neut(i, :) = [mean(half1_n), var(half1_n), std(half1_n), mean(half2_n), var(half2_n), std(half2_n)];

    % Split Overall data into two halves

        % Create per-row reproducible choice indices (1 or 2) if not already generated
    
    if isempty(Flanker_split_choice_Overall{i})
            % one random choice per condition: Cong, Incong, Neut
        Flanker_split_choice_Overall{i} = randi(2, 1, 3);   % [cChoice iChoice nChoice] each in {1,2}
    end
    choice = Flanker_split_choice_Overall{i};  % e.g., [1 2 1]
    
        % Select halves for Overall-half1 and use complementary halves for Overall-half2
    
    if choice(1) == 1
        pick1_c = half1_c;  pick2_c = half2_c;
    else
        pick1_c = half2_c;  pick2_c = half1_c;
    end
    
    if choice(2) == 1
        pick1_i = half1_i;  pick2_i = half2_i;
    else
        pick1_i = half2_i;  pick2_i = half1_i;
    end
    
    if choice(3) == 1
        pick1_n = half1_n;  pick2_n = half2_n;
    else
        pick1_n = half2_n;  pick2_n = half1_n;
    end
    
        % Build Overall halves by combining the selected halves from each condition
    half1_O = [pick1_c(:); pick1_i(:); pick1_n(:)];
    half2_O = [pick2_c(:); pick2_i(:); pick2_n(:)];
    
    results_Overall(i, :) = [mean(half1_O), var(half1_O), std(half1_O), mean(half2_O), var(half2_O), std(half2_O)];

end


% Save the split indices for both Target and Standard data
save('Flanker_split_indices.mat', 'Flanker_split_indices_Cong', 'Flanker_split_indices_Incong','Flanker_split_indices_Neut', 'Flanker_split_choice_Overall');

% Save results for SPSS
save('Flanker_ICCData', 'results_Cong', 'results_Incong', 'results_Neut', 'results_Overall')

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



