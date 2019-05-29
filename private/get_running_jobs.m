function [id, state] = get_running_jobs(account)
% GET_RUNNING_JOBS - Receive job ids of currently running jobs
%
persistent pid
if isempty(pid)
    pid = feature('getpid');
end
if nargin == 0
    account = getenv('USER');
end
tmpFile = fullfile('/tmp/', sprintf('%s_jobs_%u', account, pid));
squeueCmd = sprintf('squeue -A %s -h -o "%%A %%T">%s', account, tmpFile);

tStart = tic;
timeout = 5;
result = -1;

while (toc(tStart) < timeout)
    [result, out] = system_out_to_disk(squeueCmd);
    if result == 0
        break
    end
    pause(0.5)    
end        
assert(result == 0, 'squeue query failed: %s', out);

if ~isempty(out)
    out = textscan(out, '%f%s');
    id = uint32(out{1});
    state = out{2};
else
    id = uint32([]);
    state = {};
end
