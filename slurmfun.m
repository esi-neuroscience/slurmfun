function [out, jobs] = slurmfun(func, varargin)
% SLURMFUN - Apply a function to each element of a cell array in parallel
% using the SLURM queueing system.
%
% USAGE
% -----
%   argout = slurmfun(functionName, inputArguments1, inputArguments2, ...)
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
%   'partition'     : name of partition/queue to be submitted to. Default
%                     is the default SLURM queue.
%   'matlabCmd'     : path to matlab binary to be used. Default is the same
%                     as the submitting user
%   'stopOnError'   : boolean flag for continuing execution after a job
%                     fails. Default is true.
%   'slurmWorkingDirectory' : path to working directory where input, output
%                     and logfiles will be created. Default is
%                     /mnt/hpx/slurm/<user>/<user>_<date/, e.g.
%                     /mnt/hpx/slurm/schmiedtj/schmiedtj_20170823-125121
%   'deleteFiles'   : boolean flag for deletion of input, output and log
%                     files after completion of all jobs. Default is true.
%   'useUserPath'   : boolean flag whether the MATLAB path of the user
%                     should be used in job. Default is true.
%   'waitForReturn' : boolean flag whether MATLAB should wait for the jobs
%                     to finish before returning. Default is true.
%   'waitForToolboxes' : cell array of toolbox names to wait for. Default
%   is {}. Avilable toolboxes are
%       {'statistics_toolbox', 'signal_toolbox', 'image_toolbox', ...
%        'curve_fitting_toolbox', 'GADS_toolbox', 'optimization_toolbox'}
%
%
% OUTPUT
% ------
%   argout : cell array of output arguments
%   job    : array of SLURM Jobs that were submitted
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
[availablePartitions,defaultPartition] = get_available_partitions();
parser.addParameter('partition', defaultPartition, ...
    @(x) ischar(validatestring(x, availablePartitions)))

% copy user path
parser.addParameter('useUserPath', true, @islogical);

% MATLAB
parser.addParameter('matlabCmd', fullfile(matlabroot, 'bin', 'matlab'), @(x) ischar(x) && exist(x, 'file') == 2)

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



% parse inputs
parser.parse(func, varargin{:})

if ischar(parser.Results.func)
    func = str2func(parser.Results.func);
end

if parser.Results.useUserPath
    assert(strcmp(parser.Results.matlabCmd, ...
        fullfile(matlabroot, 'bin', 'matlab')), ...
        'If useUserPath is true, matlabBinary must match current MATLAB')
end


nArgs = length(inputArguments);
nJobs = length(inputArguments{1});
jobs(nJobs) = MatlabJob;

%% Working directory
slurmWDCreated = false;
% permissions
if ~(exist(parser.Results.slurmWorkingDirectory, 'dir') == 7)
    result = system(['mkdir -p ' parser.Results.slurmWorkingDirectory]);
    assert(result == 0, 'Could not create SLURM working directory (%s)', ...
        parser.Results.slurmWorkingDirectory)
    slurmWDCreated = true;
end
cmd = sprintf('chmod -R g+w %s', parser.Results.slurmWorkingDirectory);
result = system(cmd);
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

fprintf('Submitting %u jobs into %s at %s\n', ...
    nJobs, parser.Results.partition, datestr(now))
tic


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
    cmd = '';
    loadCmd = sprintf('load(''%s'');', jobs(iJob).inputFile);
    
    cmd = [licenseCheckoutCmd, loadCmd, userPathCmd, fexecCmd];
    jobs(iJob).run_cmd(cmd, ...
        parser.Results.partition, jobs(iJob).logFile, parser.Results.matlabCmd);
    jobs(iJob).deleteFiles = parser.Results.deleteFiles;
    
    pause(0.001)
    
end
tSubmission = toc;
fprintf('Submission of %u jobs took %g s\n', nJobs, tSubmission)

% Setup cleanup after completion/failure
if parser.Results.deleteFiles && parser.Results.waitForReturn
    cleanup = onCleanup(@() delete_if_exist([{jobs.inputFile}, {jobs.outputFile}], ...
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

for iJob = 1:nJobs
    if strcmp(jobs(iJob).state, 'COMPLETED')
        
        % load output files
        tmpOut = load(jobs(iJob).outputFile);
        out{iJob} = tmpOut.out;
        
        if isa(tmpOut.out, 'MException')
            
            warning('A MATLAB error occured in job %u:%u. See %s', ...
                iJob, jobs(iJob).id, jobs(iJob).logFile)
            warning(getReport(tmpOut.out, 'extended', 'hyperlinks', 'on' ) )
            jobs(iJob).deleteFiles = false;
        end
    end
end


iCompleted = ~cellfun(@isempty, out);
iMatlabError = cellfun(@(x) isa(x, 'MException'), out(iCompleted));


fprintf('\n')
fprintf('%u jobs completed without errors, %u completed with errors, %u failed/aborted.\n', ...
    sum(~iMatlabError), sum(iMatlabError), sum(~iCompleted));
% fprintf('Elapsed time: %g s\n', toc(tStart));

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

