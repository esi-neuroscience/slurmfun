function [id, state] = get_running_jobs(account)
% GET_RUNNING_JOBS - Receive job ids of currently running jobs
% 
if nargin == 0
    account = getenv('USER');
end
squeueCmd = sprintf('squeue -A %s -h -o "%%A %%T"', account);
[result, allJobs] = system_read_buffer_until_empty(squeueCmd);
assert(result == 0, 'squeue query failed');


if isempty(allJobs)
    id = [];
    state = [];
    return
end
out = textscan(allJobs, '%f%s');

id = uint32(out{1});
state = out{2};


