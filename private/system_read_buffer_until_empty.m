function [status, output] = system_read_buffer_until_empty(varargin)
% SYSTEM_READ_BUFFER_UNTIL_EMPTY - MATLAB bug workaround
% 
% See https://www.mathworks.com/support/bugreports/1400063

[status, output] = system(varargin{:});
[~, remainder] = system('');
while ~isempty(remainder)   
	output = [output, remainder];         
    [~, remainder] = system('');    
end