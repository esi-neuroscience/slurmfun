%
% Query running jobs for user
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function [id, state, partition, started] = get_active_jobs(jobs)
% GET_RUNNING_JOBS - Receive info of currently running jobs
%
persistent pid
if isempty(pid)
    pid = feature('getpid');
end
account = getenv('USER');
squeueBase = 'squeue -A %s -h -o "%%A %%T %%P %%S" --name=matlabcmd.sh';
if nargin > 0
    if isa(jobs, 'MatlabJob')
        jobids = zeros(1, length(jobs), 'uint32');
        for i = 1:length(jobs)
            jobids(i) = jobs(i).id;
        end
    elseif isnumeric(jobs)
        jobids = jobs;
    else
        error('Wrong input type for jobs')
    end
    joblist = sprintf('%d', jobids(1));
    for i = 2:length(jobids)
        joblist = sprintf('%s,%d', joblist, jobids(i));
    end
    squeueBase = sprintf('%s --jobs=%s', squeueBase, joblist);
end
squeueCmd = sprintf(squeueBase, account);

tStart = tic;
timeout = 300;
result = -1;

% tolerate an unresponsive SLURM controller for 5 min
while (toc(tStart) < timeout)
    [result, out] = system_out_to_disk(squeueCmd);
    if result == 0
        break
    end
    pause(10)    
end

if result ~= 0
    warning('squeue query failed: %s', out);
    id = uint32([]);
    state = {};
    partition = {};
    started = {};
    return
end

if ~isempty(out)
    out = textscan(out, '%f%s%s%s');
    id = uint32(out{1});
    state = out{2};
    partition = out{3};
    started = out{4};
else
    id = uint32([]);
    state = {};
    partition = {};
    started = {};
end
