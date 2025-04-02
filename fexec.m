%
% Interprete string as MATLAB function
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function out = fexec(func, inputVars, outputFile)
%
% input file must contain the variables func, inputVars, outputFile
fprintf('Trying to evaluate %s\n', func2str(func))
try
    
    nOutput = nargout(func);
    if nOutput > 1
        out = cell(1, nOutput);
        [out{:}] = feval(func, inputVars{:});
    elseif nOutput == 1
        out = feval(func, inputVars{:});
    elseif nOutput == 0
        out = 'no output';
        feval(func, inputVars{:});
    else
        error('Unsupported number of output arguments (%d)', nOutput)
    end
    outSize = whos('out');
    if outSize.bytes > 2*1024*1024*1024
        error(['Size of the output arguments must not exceed 2 GB. ', ...
            'For large data please save to disk in your function'])
    end
    
catch me
    me.display();
    out = me;
    
end

fprintf('Storing output in %s\n', outputFile)
save(outputFile, 'out', '-v6')

exit
