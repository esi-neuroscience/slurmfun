%
% Get output from Linux system command
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function [status, output] = system_read_buffer_until_empty(varargin)
% SYSTEM_READ_BUFFER_UNTIL_EMPTY - MATLAB bug workaround
% 
% See https://www.mathworks.com/support/bugreports/1400063

[status, output] = system(varargin{:});
[~, remainder] = system('');
bufferEmpty = isempty(remainder);
while ~bufferEmpty           
    pause(1)
    [~, remainder] = system('');
	output = [output, remainder];             
    bufferEmpty = isempty(remainder);       
end
