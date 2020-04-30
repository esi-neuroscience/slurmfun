function [result, out] = system_out_to_disk(cmd)
% SYSTEM_OUT_TO_DISK - Execute system command and return result.
%
%   [status, result] = system_out_to_disk('command')
% 
% In rare cases on Linux, using system may not return the complete buffer.
% This function is a workaround that pipes the output into a file and reads
% it back in.
% 
% See also system
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