addpath(fileparts(fileparts(mfilename('fullpath'))))

clc

delim = repmat(['-'], 1, 80);
testStart = datetime('now');
fprintf('<strong>%s\n\t\t Test Session Starts at %s\n%s</strong>\n', delim, testStart, delim);

% prepare defaults based on cluster
machine = getenv('HOSTNAME');
if contains(machine, 'bic-svhpc')
  fprintf('Running on CoBIC cluster node %s\n\n', machine);
  defaultPartition = '8GBSx86';
  partition = {'8GBSx86', '16GBSx86', '32GBSx86'};
elseif contains(machine, 'esi-svhpc')
  fprintf('Running on ESI cluster node %s\n\n', machine);
  defaultPartition = '8GBXS';
  partition = {'8GBXS', '16GBXS', '32GBXS'};
else
  error('Unknown cluster node %s - cannot run tests', machine);
end

dbstop if error

%% Start `nJobs` in `defaultPartition` and allocate ~2.3 GB array
fprintf('\t Test array allocation in %s...\n', defaultPartition)
nJobs = 5;
inputArgs1 = num2cell(randi(20,nJobs,1)+60);
inputArgs2 = num2cell(randi(20,nJobs,1)+60);
inputArgs1{end+1} = 5000000;
inputArgs2{end+1} = 1;
[out, jobs] = slurmfun(@myfunction, inputArgs1, inputArgs2, ...
    'partition', defaultPartition, ...
    'stopOnError', false, ...
    'deleteFiles', true, ...
    'waitForToolboxes', {}, ...
    'mem', '7500M', ...
    'cpu', 1, ...
    'waitForReturn', true);
assert(numel(out) == nJobs + 1)
fprintf('\t Passed\n%s\n', delim)

%% test varying partitions
fprintf('\t Test multiple partitions/CPU/mem specs...\n')
mem = {'7500M', '15500M', '7500'};
cpu = [1, 1, 4];
nJobs = 3;
inputArgs1 = num2cell(randi(20,nJobs,1)+60);
inputArgs2 = num2cell(randi(20,nJobs,1)+60);
[out, jobs] = slurmfun(@myfunction, inputArgs1, inputArgs2, ...
    'partition', partition, ...
    'stopOnError', false, ...
    'deleteFiles', true, ...
    'waitForToolboxes', {}, ...
    'mem', mem, ...
    'cpu', cpu, ...
    'waitForReturn', true);
assert(numel(out) == nJobs)
for i = 1:3
    assert(size(out{i}, 1) == inputArgs1{i})
    assert(size(out{i}, 2) == inputArgs2{i})
end
fprintf('\t Passed\n%s\n', delim)

%% no outputs
fprintf('\t Test function with no outputs...\n')
[out, jobs] = slurmfun(@function_without_output, {'in1'}, {'in2'}, ...
    'partition', defaultPartition, ...
    'stopOnError', false, ...
    'deleteFiles', true, ...    
    'waitForReturn', true);
assert(strcmp(out{1}, 'no output'))
fprintf('\t Passed\n%s\n', delim)

%% multiple outputs
fprintf('\t Test function with multiple outputs...\n')
[out, jobs] = slurmfun(@function_with_multiple_outputs, {'in1'}, {'in2'}, ...
    'partition', defaultPartition, ...
    'stopOnError', false, ...
    'deleteFiles', true, ...    
    'waitForReturn', true);
assert(numel(out{1}) == 2);
fprintf('\t Passed\n%s\n', delim)

%% handle errors in user functions
fprintf('\t Test error handling...\n')
expectedError = 'Unrecognized function or variable ''jgldjdfgl''.';
try
     [out, jobs] = slurmfun(@myfunction_with_errors, inputArgs1(1), ...
                            'partition', defaultPartition, ...
                            'stopOnError', true, ...
                            'deleteFiles', false, ...
                            'waitForToolboxes', {}, ...
                            'waitForReturn', true);
catch ME
     assert(contains(ME.message, expectedError));
end
[out, jobs] = slurmfun(@myfunction_with_errors, inputArgs1(1), ...
                       'partition', defaultPartition, ...
                       'stopOnError', false, ...
                       'deleteFiles', false, ...
                       'waitForToolboxes', {}, ...
                       'waitForReturn', true);
assert(contains(out{1}.message, expectedError));
fprintf('\t Passed\n%s\n', delim)

%% end of test session
testEnd = datetime('now');
testDur = testEnd - testStart;
testDur.format = 'mm:ss';
fprintf('<strong>\t\t ALL PASSED in %s\n%s</strong>\n', testDur, delim)
