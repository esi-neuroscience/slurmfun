function [id, state] = get_running_jobs(account)
% GET_RUNNING_JOBS - Receive job ids of currently running jobs
%
if nargin == 0
    account = getenv('USER');
end
tmpFile = fullfile('/tmp/', sprintf('%s_jobs_%u', account, round(now*1E6)));
squeueCmd = sprintf('squeue -A %s -h -o "%%A %%T">%s', account, tmpFile);
[result, ~] = system(squeueCmd);

assert(result == 0, 'squeue query failed');

fid = fopen(tmpFile, 'r');
finishup = onCleanup(@() @cleanup_files);

out = textscan(fid, '%f%s');

fclose(fid);
delete(tmpFile)

id = uint32(out{1});
state = out{2};

    function cleanup_files
        fclose(fid);
        delete(tmpFile)
    end

end
