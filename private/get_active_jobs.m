function [id, state] = get_active_jobs(account)
% GET_RUNNING_JOBS - Receive job ids of currently running jobs
%
persistent pid
if isempty(pid)
    pid = feature('getpid');
end
if nargin == 0
    account = getenv('USER');
end

squeueCmd = sprintf('squeue -A %s -h -o "%%A %%T"', account);

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
    return
end

if ~isempty(out)
    out = textscan(out, '%f%s');
    id = uint32(out{1});
    state = out{2};
else
    id = uint32([]);
    state = {};
end
