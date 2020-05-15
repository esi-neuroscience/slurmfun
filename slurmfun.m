function [out, jobs] = slurmfun(func, varargin)
% SLURMFUN - Apply a function to each element of a cell array in parallel
% using the SLURM queueing system.
%
% USAGE
% -----
%   [out, {jobInfo} = slurmfun(functionName, inputArguments1, inputArguments2, ...)
%
% INPUT
% -----
%   functionName    : function name or handle to executed. The function
%                     must only take one input argument and give out one
%                     output argument. Multiple arguments can be stored in
%                     cell arrays.
%   inputArguments  : cell array of input arguments for function. Length of
%                     the array determines number of jobs submitted to SLURM.
%
% This function has a number of optional arguments for configuration:
%   'partition'     : name(s) of partition/queue to be submitted to. Default
%                     is the default SLURM queue.
%   'mem'           : bytes of memory to be used for each cpu as str or 
%                     cell array of str. Unit are K, M or G.
%                     Default='', i.e. partition default
%   'cpu'           : number of cpu cores to be used for each job.
%                     Default=1
%   'matlabCmd'     : path to matlab binary to be used. Default is the same
%                     as the submitting user
%   'stopOnError'   : boolean flag for continuing execution after a job
%                     fails. Default=true.
%   'slurmWorkingDirectory' : path to working directory where input, output
%                     and logfiles will be created. Default is
%                     /mnt/hpx/slurm/<user>/<user>_<date/, e.g.
%                     /mnt/hpx/slurm/schmiedtj/schmiedtj_20170823-125121
%   'deleteFiles'   : boolean flag for deletion of input, output and log
%                     files after completion of all jobs. Default=true.
%   'useUserPath'   : boolean flag whether the MATLAB path of the user
%                     should be used in job. Default=true.
%   'waitForReturn' : boolean flag whether MATLAB should wait for the jobs
%                     to finish before returning. Default=true. If
%                     false, the out argument is an ObjectArray of
%                     MatlabJob elements. Use the wait_for_jobs function to
%                     wait until completion.
%   'waitForToolboxes' : cell array of toolbox names to wait for. Default={}. 
%
%
% OUTPUT
% ------
%   argout : cell array of output arguments returned by @functionName
%   jobInfo: array of SLURM Jobs that were submitted
%
% EXAMPLE
% -------
% This example will spawn 50 jobs that pause for 50-70s.
%
% nJobs = 50;
% inputArgs = num2cell(randi(20,nJobs,1)+50);
% out = slurmfun(@pause, inputArgs, ...
%     'partition', '8GBS', ...
%     'stopOnError', false);
%
%
%
% See also CELLFUN, wait_for_jobs
%

if verLessThan('matlab', 'R2014a') || verLessThan('MATLAB', '8.3')
    error('MATLAB:slurmfun:MATLAB versions older than R2014a are not supported')
end

% empty the LD_PRELOAD environment variable
% vglrun libraries don't have SUID bit, sbatch does. See
% ihttps://virtualgl.org/vgldoc/2_2/#hd0012

LD_PRELOAD = getenv('LD_PRELOAD');
if ~isempty(LD_PRELOAD)
    setenv('LD_PRELOAD', '');
end

toolboxes = ver;


%% Handle inputs
parser = inputParser;

% function
parser.addRequired('func', @(x) isa(x, 'function_handle')||ischar(x));

% partitions
[~ ,defaultPartition] = get_available_partitions();
parser.addParameter('partition', defaultPartition, ...
    @validate_partition)

% number of CPU Cores per job
parser.addParameter('cpu', 1, @isnumeric);

% allocated memory of each job
parser.addParameter('mem', '', ...
    @(x) ischar(x) || iscell(x));

% copy user path
parser.addParameter('useUserPath', true, @islogical);

% MATLAB
parser.addParameter('matlabCmd', fullfile(matlabroot, 'bin', 'matlab'), ...
    @(x) ischar(x) && exist(x, 'file') == 2)

% SLURM home folder
account = getenv('USER');
submissionTime = datestr(now, 'YYYYmmDD-HHMMss');
parser.addParameter('slurmWorkingDirectory', ...
    fullfile('/mnt/hpx/slurm', account, [account '_' submissionTime]), @isstr);

% stop on error
parser.addParameter('stopOnError', true, @islogical);

% wait for jobs to complete
parser.addParameter('waitForReturn', true, @islogical);

% delete files
parser.addParameter('deleteFiles', true, @islogical);

% wait for toolbox licenses
availableToolboxes = {'statistics_toolbox', 'signal_toolbox', 'image_toolbox', ...
    'curve_fitting_toolbox', 'GADS_toolbox', 'optimization_toolbox'};
parser.addParameter('waitForToolboxes', {}, @(x) all(ismember(x, availableToolboxes)));

% extract input arguments from varargin
iFirstParameter = find(cellfun(@(x) ~iscell(x), varargin), 1);
inputArguments = varargin(1:iFirstParameter-1);

varargin = varargin(iFirstParameter:end);
% input arguments
%parser.addRequired('inputArguments', @iscell);
% assert(cellfuniscell(inputArguments), 'Input arguments must a cell array')


nArgs = length(inputArguments);
nJobs = length(inputArguments{1});

% parse inputs
parser.parse(func, varargin{:})

if ischar(parser.Results.func)
    func = str2func(parser.Results.func);
end

if ischar(parser.Results.partition)
   partition = repmat({ parser.Results.partition}, [1, nJobs]);
else
    assert(length(parser.Results.partition) == nJobs, ...
        'Number of defined partitions must be single string or cell array of same length as jobs')    
    partition = parser.Results.partition;
end
    
if ischar(parser.Results.mem)
   mem = repmat({ parser.Results.mem}, [1, nJobs]);
elseif iscell(parser.Results.mem)
    assert(length(parser.Results.mem) == nJobs, ...
        'Number of memory must be single string or cell array of same length as jobs')    
    mem = parser.Results.mem;
end


if length(parser.Results.cpu) == 1
    cpu = repmat(parser.Results.cpu, [1, nJobs]);
elseif length(parser.Results.cpu) == nJobs
    cpu = parser.Results.cpu;
else
    error('Length of cpu array doesn''t match number of jobs')
end

if parser.Results.useUserPath
    assert(strcmp(parser.Results.matlabCmd, ...
        fullfile(matlabroot, 'bin', 'matlab')), ...
        'If useUserPath is true, matlabBinary must match current MATLAB')
end

jobs(nJobs) = MatlabJob;

%% Working directory
slurmWDCreated = false;
% permissions
if ~(exist(parser.Results.slurmWorkingDirectory, 'dir') == 7)
    result = system_read_buffer_until_empty(['mkdir -p ' parser.Results.slurmWorkingDirectory]);
    assert(result == 0, 'Could not create SLURM working directory (%s)', ...
        parser.Results.slurmWorkingDirectory)
    slurmWDCreated = true;
end
cmd = sprintf('chmod -R g+w %s', parser.Results.slurmWorkingDirectory);
result = system_read_buffer_until_empty(cmd);
assert(result == 0, ...
    'Could not set write permissions for SLURM working directory (%s)', ...
    parser.Results.slurmWorkingDirectory)



%% Create input files
addpath(pwd)
userPath = path(); %#ok<*NASGU>
inputFiles = cell(1,nJobs);
outputFiles = cell(1,nJobs);
logFiles = cell(1,nJobs);
fprintf('Creating input files in %s\n', parser.Results.slurmWorkingDirectory);
for iJob = 1:nJobs
    
    baseFile = fullfile(parser.Results.slurmWorkingDirectory, ...
        sprintf('%s_%s_%05u', account, submissionTime, iJob));
    
    jobs(iJob).inputFile = [baseFile '_in.mat'];
    jobs(iJob).outputFile = [baseFile '_out.mat'];
    jobs(iJob).logFile = [baseFile '.log'];
    
    
    inputArgs = cellfun(@(x) x{iJob},  inputArguments, 'UniformOutput', false);
    outputFile = jobs(iJob).outputFile;
    inputArgsSize = whos('inputArgs');
    if inputArgsSize.bytes > 2*1024*1024*1024
        error(['Size of the input arguments must not exceed 2 GB. ', ...
            'For large data please pass a filename instead of the data'])
    end
    save(jobs(iJob).inputFile, 'func', 'inputArgs', 'userPath', 'outputFile', '-v6')
end
%% Submit jobs

fprintf('Submitting %u jobs into %d partitions at %s\n', ...
    nJobs, length(unique(partition)), datestr(now))

tSubmission = tic;


licenseCheckoutCmd = '';
if ~isempty(parser.Results.waitForToolboxes)
    licenseCheckoutCmd = 'fprintf(''Waiting for licenses\n'');';
    for iToolbox = 1:length(parser.Results.waitForToolboxes)
        toolboxName = parser.Results.waitForToolboxes{iToolbox};
        licenseCheckoutCmd = [licenseCheckoutCmd, ...
            sprintf([   'licenseAvailable = false;', ...
            'while ~licenseAvailable;', ...
            '[licenseAvailable, ~] = license(''checkout'',''%s'');', ...
            'pause(15);', ...
            'end;'], ...
            toolboxName);];
    end
end

if parser.Results.useUserPath
    userPathCmd = 'fprintf(''Loading userpath\n''), path(userPath);';
else
    userPathCmd = '';
end
fexecCmd = 'try fexec(func, inputArgs, outputFile); catch exit; end';


for iJob = 1:nJobs
    
    % set job parameters
    jobs(iJob).partition = partition{iJob};
    jobs(iJob).allocCPU = cpu(iJob);
    jobs(iJob).allocMEM = mem{iJob};
    
    % construct MATLAB command
    cmd = '';
    loadCmd = sprintf('load(''%s'');', jobs(iJob).inputFile);
    cmd = [licenseCheckoutCmd, loadCmd, userPathCmd, fexecCmd];
    jobs(iJob).run_cmd(cmd);
    jobs(iJob).deleteFiles = parser.Results.deleteFiles;
    
    pause(0.005)
    
end

fprintf('Submission of %u jobs took %.0f s\n', nJobs, toc(tSubmission))

% Setup cleanup after completion/failure
if parser.Results.deleteFiles && parser.Results.waitForReturn
    cleanup = onCleanup(@() delete_if_exist([{jobs.inputFile}, {jobs.outputFile}, {jobs([jobs.deleteFiles]).logFile}], ...
        parser.Results.slurmWorkingDirectory, slurmWDCreated, LD_PRELOAD));
end

%% Wait for jobs
if ~parser.Results.waitForReturn
    out = jobs;
    return
end
jobs = wait_for_jobs(jobs, parser.Results.stopOnError);


%% Retreive results
out = cell(1,nJobs);
fprintf('Retreiving job results\n')
for iJob = 1:nJobs
    if strcmp(jobs(iJob).state, 'COMPLETED')
        
        % load output files
        tmpOut = load(jobs(iJob).outputFile);
        out{iJob} = tmpOut.out;
        
        if isa(tmpOut.out, 'MException')
            msg = sprintf('A MATLAB error occured in job %u (id %u).\nFull log: <a href="matlab: opentoline(''%s'',1)">%s</a>', ...
                iJob, jobs(iJob).id, jobs(iJob).logFile, jobs(iJob).logFile);
            warning(msg)
            warning(getReport(tmpOut.out, 'extended', 'hyperlinks', 'on' ) )
            jobs(iJob).deleteFiles = false;
            if parser.Results.stopOnError
                rethrow(tmpOut.out)                            
            end
            
        end
    end
end


iCompleted = ~cellfun(@isempty, out);
iMatlabError = cellfun(@(x) isa(x, 'MException'), out(iCompleted));


fprintf('\n')
fprintf('%u jobs completed without errors, %u completed with errors, %u failed/aborted.\n', ...
    sum(~iMatlabError), sum(iMatlabError), sum(~iCompleted));


memUsed = cellfun(@(x) str2double(x)/1024/1024/1024, {jobs.memoryUsed}); % GB
duration = [jobs.duration]/60; % s
readData = cellfun(@(x) str2double(x(1:end-1))/1024, {jobs.readFromDisk}); % GB
writtenData = cellfun(@(x) str2double(x(1:end-1))/1024, {jobs.wroteToDisk}); % GB

report_data = @(name,unit,data) fprintf('%s: %.1f+-%.1f %s', ...
    name, mean(data), std(data), unit);
report_data('MEMORY', 'GB', memUsed)
fprintf(' | ')
report_data('JOB DURATION', 'min', duration)
fprintf(' | ')
report_data('READ', 'GB', readData)
fprintf(' | ')
report_data('WRITTEN', 'GB', writtenData)
fprintf('\n')
fprintf('Total time: %g min (%.1f x faster than sequential computation)\n', ...
    toc(tSubmission)/60, sum([jobs.duration])/toc(tSubmission));

if sum(iMatlabError) > 0
    fprintf('Log files of failed jobs can be found in %s\n', ...
        parser.Results.slurmWorkingDirectory);
end

if nargout == 0
    clear out
end

end


function delete_if_exist(delFiles, delFolder, folderFlag, LD_PRELOAD)
fprintf('Deleting temporary input/output files from %s...\n', delFolder)
warning('off', 'MATLAB:DELETE:FileNotFound')
delete(delFiles{:})
warning('on', 'MATLAB:DELETE:FileNotFound')


% delete working directory if empty and created by slurmfun
if folderFlag && length(dir(delFolder)) == 2
    fprintf('Deleting SLURM working directory %s ...\n', delFolder)
    rmdir(delFolder)
end

% restore original LD_PRELOAD variable
setenv('LD_PRELOAD', LD_PRELOAD)

end

