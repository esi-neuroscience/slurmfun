%
% Get GID of user
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function gid = primary_group()
[result, gid] = system_read_buffer_until_empty('id -g ');
if result == 0 
    gid = str2double(gid);
else
    error('Could not determine primary group of user');
end
