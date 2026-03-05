% % Note: This script is set up for the Zero-Back condition by default.
% % It can be generalized to other conditions (e.g., One-Back, Two-Back)
% % by updating the input data files and variable names accordingly.

% % The loaded files (e.g., ZeroBack1_Data.mat, ZeroBack2_Data.mat)
% % are produced by the corresponding n_Back_Trial_m.m file.


clc
clear;
close all;

N_participants= 65; % Number of expected Participants


%% Looking for Zero Back Data

load('ZeroBack1_Data.mat');
load('ZeroBack2_Data.mat');

[commonIDs, idx1, idx2] = intersect(cell2mat(Count1(2:end,:)), cell2mat(Count2(2:end,:)));


%% Overall

for i = 1:length(commonIDs)

    
    OverallTargetRespTime(i,:) = [TargetRespTime1(idx1(i), :), TargetRespTime2(idx2(i), :)];
    OverallTargetRespCount(i,:) = TargetRespCount1(idx1(i), :) + TargetRespCount2(idx2(i), :);

    OverallStandardRespTime(i,:) = [StandardRespTime1(idx1(i), :), StandardRespTime2(idx2(i), :)];
    OverallStandardRespCount(i,:) = StandardRespCount1(idx1(i), :) + StandardRespCount2(idx2(i), :);

    OverallRespTime(i,:) = [OverallTargetRespTime(i, :), OverallStandardRespTime(i, :)];
    OverallRespCount(i,:) = OverallTargetRespCount(i, :) + OverallStandardRespCount(i, :);

    % TARGETs Response Time Avg
    BehavioralCount(i,1) = sum(OverallTargetRespTime(i,:))/OverallTargetRespCount(i,1);
    % TARGETs Response Time Std
    BehavioralCount(i,2) = std(OverallTargetRespTime(i, OverallTargetRespTime(i, :) ~= 0));

    % STANDARDs Response Time Avg
    BehavioralCount(i,3) = sum(OverallStandardRespTime(i,:))/OverallStandardRespCount(i,1);
    % STANDARDs Response Time Std
    BehavioralCount(i,4) = std(OverallStandardRespTime(i, OverallStandardRespTime(i, :) ~= 0)) ;

    % Overall Response Time Avg
    BehavioralCount(i,5) = sum(OverallRespTime(i,:))/OverallRespCount(i,1);
    % Overall Response Time Std
    BehavioralCount(i,6) = std(OverallRespTime(i, OverallRespTime(i, :) ~= 0));
end

Target_correct = TargetRespCount1(idx1,:) + TargetRespCount2(idx2,:);
Standard_correct = StandardRespCount1(idx1,:) + StandardRespCount2(idx2,:);
Behavioral_Count = BehavioralCount1(idx1,:) + BehavioralCount2(idx2,:);
Overal_Count = cell2mat(Count_1(idx1+1,:)) + cell2mat(Count_2(idx2+1,:));


%% Generating Data for ICC Analysis

% Assuming OverallRespTime, OverallRespCount exist

[numRows, ~] = size(OverallRespTime);

% Output matrix: columns -> Mean_Half1, Var_Half1, Std_Half1, Mean_Half2, Var_Half2, Std_Half2
NBack0_results = zeros(numRows, 6);

for i = 1:numRows
    half1 = [TargetRespTime1(idx1(i), :), StandardRespTime1(idx1(i), :)];  % First, select the correct rows
    half1 = half1(half1 ~= 0);     % Then remove zero elements
    half2 = [TargetRespTime2(idx2(i), :), StandardRespTime2(idx2(i), :)]; 
    half2 = half2(half2 ~= 0);
    NBack0_results(i, :) = [mean(half1), var(half1), std(half1), mean(half2), var(half2), std(half2)];
end

