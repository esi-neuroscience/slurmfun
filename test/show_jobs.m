function show_active_jobs(varargin)
% SHOW_ACTIVE_JOBS - Print summary of active SLURM JOBS
%
%       show_active_jobs(jobs)
%
% INPUT
% -----
%        jobs : (OPTIONAL) array of job ids or MatlabJob array as returned by slurmfun
%
% OUTPUT
% ------
%
% See also wait_for_jobs

[activeIds, state, partition, started] = get_active_jobs(varargin{:});
nJobs = length(activeIds);

if nJobs == 0;
    fprintf('No active jobs found\n')
    return
end

fprintf('\nFound %d active jobs:\n\n', nJobs)
fprintf('JobID\tPartition\tStarted\tState\n')
for i = 1:nJobs
    fprintf('%d\t%s\t%s\t%s\n', activeIds(i), partition{i}, started{i}, state{i})
end
fprint('\nUse scontrol show job <jobid> to see more information\n')
