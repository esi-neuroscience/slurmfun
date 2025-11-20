%
% Example script for invoking `slurmfun` with a user-defined function
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%

close all
clear

%% Configure fractal computation
xpos = -1.2676;
ypos = 0.3554;

steps = 1000;
span = 2;
maxcount = 50;
zoom = 0.98;

cfg = {};
for count = 1:maxcount
    cfg{count}.xpos = xpos;
    cfg{count}.ypos = ypos;
    cfg{count}.span = span;
    cfg{count}.steps = steps;
    span = span*zoom;
end

%% Local, sequential computation
% tStart = tic;
% Z = cellfun(@calcfrac, cfg, 'UniformOutput', false);
% tSequential = toc;
% fprintf('Sequential computation took %g s\n', tSequential)


%% Parallel computation
% Prepare default partition based on used cluster
machine = getenv('HOSTNAME');
if contains(machine, 'bic-svhpc')
    fprintf('Running on CoBIC cluster node %s\n\n', machine);
    defaultPartition = '8GBSx86';
elseif contains(machine, 'esi-svhpc')
    fprintf('Running on ESI cluster node %s\n\n', machine);
    defaultPartition = '8GBXS';
else
    error('Unknown cluster node %s - please set `partition` below manually', machine);
end

tStart = tic;
Z = slurmfun(@calcfrac, cfg, 'partition', defaultPartition);
tParallel = toc;

%% animate
fig = figure;
ax = axis;
h = imagesc(Z{1});
axis off
for count = 2:maxcount
    set(h, 'CData', Z{count})
    drawnow
    pause(0.017)
end

