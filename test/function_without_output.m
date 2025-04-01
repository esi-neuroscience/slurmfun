%
% Test function without any output argument
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function function_without_output(in1, in2)


tWait = randi(10)+20;
fprintf('Pausing for %g s\n', tWait)
pause(tWait);

