% This is the first attempt at writing an icp based slam algorithm using icp_1
% Author: Josh M
%
clear map world pose pose_dot graphStruct
close all
clc

% Load simulated dataset
%load hall_and_room_set.mat

% Add noise to the dataset
%LidarScan = LidarScan + normrnd(0.05,0.01,size(LidarScan,1),size(LidarScan,2));
error = [0;0;0];

pose=[0;0;0];
pose_dot=[];

% This is what I am the last scan to, whether it be the full map or just
% scan-by-scan
map = [];
world = [];

%intitialize the graph structure
graph.n = 150;
graph.m = 150;
graph.width = 2; %meters
graph.nodemat = repmat(struct('data', [], 'visited', 0, 'n', 0), graph.n, graph.m);

ndx = 1;
ndy = 1;

Hokuyo_freq = 40; %Hz
LidarRange = 30;
nScanIndex = unique(Lidar_ScanIndex);
%radius to filter out points when running icp
filter_radius = LidarRange * 0.9;
theta_offset = deg2rad(0.5);

rejection_setting = 0.2;
converge_metric = 1e-4;

frame = 1;
frame_skip = 50;
for nScan = 1:frame_skip:size(nScanIndex)
    
    dp = [[0 1];[0 0]];
    
    % Retrieve each scan's points
    nIndex = nScanIndex(nScan);
    I = nIndex == Lidar_ScanIndex;
    
    a = Lidar_Angles(I,:)' + theta_offset;
    z = Lidar_Ranges(I,:)';
    
    %  Remove out of range measurements
    I = (z >= LidarRange*0.9);
    a(I) = [];
    z(I) = [];
    
    [x,y] = pol2cart(a,z);
    
    raw = [x;y];
    
    if isempty(map)
        % initialize the map
        map = raw;
    else
        
        % Transfrom the current scan to the current estimated pose
        % based on a constantant velocity assumption.
        if size(pose,2) > 1
            TT = repmat(pose(1:2,end) + pose_dot(1:2), 1, size(raw,2));
            phi = pose(3,end) + pose_dot(3);
            TR = [cos(phi) (-sin(phi)); sin(phi) cos(phi)];
            
            raw = TR*raw + TT;
            dp = TR*dp + TT(:,1:2);
        end
        
        %run the manela icp algorithm
        [cur, pose, pose_dot, raw, dp] = manela_icp(map, raw, pose, pose_dot, ...
            dp, rejection_setting, converge_metric);
        
        world = [world raw];
        
        %update the graph and get our next map
        [ graph, ndx, ndy, map ] = update_graph( graph, raw, ndx, ndy, pose);

    end
    
    plot_scans

    %pause so we can display things
    pause(0.1);
    
    %not really using, but may be helpful in the future
    frame = frame + 1;
end

%plot_scans

profile viewer
profile off