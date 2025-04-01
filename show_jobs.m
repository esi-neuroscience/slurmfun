%
% Show user's active slurmfun jobs
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function show_jobs(varargin)
% SHOW_JOBS - Print summary of active SLURM JOBS
%
%       show_jobs(jobs)
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
fprintf('JobID\t\tPartition\tStarted\t\t\tState\n')
for i = 1:nJobs
    fprintf('%d\t%s\t\t%s\t%s\n', activeIds(i), partition{i}, started{i}, state{i})
end
fprintf('\nUse scontrol show job <jobid> to see more information\n')
