close all
clear

%% Configure fractal computation
xpos = -1.2676;
ypos = 0.3554;

steps = 1000;
span = 2;
maxcount = 1000;
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
tStart = tic;
Z = slurmfun(@calcfrac, cfg, 'partition','8GBS');
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

