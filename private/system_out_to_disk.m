function [result, out] = system_out_to_disk(cmd)
persistent pid
if isempty(pid)
    pid = feature('getpid');
end
user = getenv('USER');

tmpFile = fullfile('/tmp/', sprintf('%s_matlab_%u', user, pid));


cmd = sprintf('%s > %s', cmd, tmpFile);



[result, ~] = system(cmd);
% finishup = onCleanup(@() @cleanup_files);

% fid = fopen(tmpFile, 'r');
out = fileread(tmpFile);
% fclose(fid);
delete(tmpFile)