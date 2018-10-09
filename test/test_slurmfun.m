
clc
% addpath /opt/ESIsoftware/slurmfun
dbstop if error
nJobs = 10;
inputArgs1 = num2cell(randi(20,nJobs,1)+60);
inputArgs2 = num2cell(randi(20,nJobs,1)+60);
inputArgs1{end+1} = 5000000000;
inputArgs2{end+1} = 1;

[out, jobs] = slurmfun(@myfunction, inputArgs1, inputArgs2, ...
    'partition', '8GBS', ...
    'stopOnError', false, ...
    'deleteFiles', true, ...
    'waitForToolboxes', {}, ...
    'waitForReturn', false);


%%
[out2, jobs2] = slurmfun(@myfunction_with_errors, inputArgs1(1), ...
    'partition', '8GBS', ...
    'stopOnError', false, ...
    'deleteFiles', false, ...
    'waitForToolboxes', {}, ...
    'waitForReturn', false);



% out = slurmfun(@pause, {4000}, ...
%     'partition', '8GBS', ...
%     'stopOnError', false, ...
%     'deleteFiles', false, ...
%     'waitForToolboxes', {});
