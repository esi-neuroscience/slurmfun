function jobInfo = sacct_query(jobId)
% SACCT_QUERY - Query info about job from SLURM accounting database

% see man sacct for possible fields
fields = {...
    'AllocCPUs', ...
    'AllocNodes', ...
    'Account', ...    
    'Cluster', ...
    'CPUTime', ... 
    'ExitCode', ...
    'Elapsed', ... 
    'End', ...
    'GID', ...
    'Group', ...
    'JobID', ...
    'MaxRSS', ... % Maximum resident set size of all tasks in job. 
    'MaxVMSize', ... % Maximum Virtual Memory size of all tasks in job. 
    'MaxDiskRead', ...
    'MaxDiskWrite', ...
    'NodeList', ...
    'Partition', ...
    'QOS', ...
    'ReqMem', ...
    'ReqTres', ...
    'Start', ...
    'State', ...
    'Timelimit', ...
    'UID', ...
    'User' ...        
    };
 
outputFormat = sprintf('%s,', fields{:});
outputFormat(end) = '';

cmd = sprintf('sacct -o %s -j %d -P -n', outputFormat, jobId);

[status, output] = system(cmd);
[~, remainder] = system('');
output = [output, remainder];
assert(status == 0, 'Could not retreive job status of job %d', jobId)


% parse output
output = splitlines(output);
jobOutput = output{1};
jobOutput = strsplit(strrep(jobOutput, newline, ''), '|', 'CollapseDelimiters', false);
jobInfo = cell2struct(jobOutput, fields,2);

%% get memory consumption if complete
if length(output) > 2
    batchOutput = output{end-1};
    batchOutput = strsplit(strrep(batchOutput, newline, ''), '|', 'CollapseDelimiters', false);
    batchOutput = cell2struct(batchOutput, fields,2);
    jobInfo.MaxRSS = batchOutput.MaxRSS;
    jobInfo.MaxVMSize = batchOutput.MaxVMSize;
    jobInfo.MaxDiskRead = batchOutput.MaxDiskRead;
    jobInfo.MaxDiskWrite = batchOutput.MaxDiskWrite;
end


