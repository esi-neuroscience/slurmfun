%
% Test function with multiple output arguments
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function [out1, out2] = function_with_multiple_outputs(in1, in2)


tWait = randi(10)+20;
fprintf('Pausing for %g s\n', tWait)
pause(tWait);
out1 = 0;
out2 = {'out2'};

