%
% Prototypical test function
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function out = myfunction(in1, in2)

fprintf('Creating %g random numbers\n', in1)
out = rand(in1,in2);
tWait = randi(10)+20;
fprintf('Pausing for %g s\n', tWait)
pause(tWait);

