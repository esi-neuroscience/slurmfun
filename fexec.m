function out = fexec(func, inputVars, outputFile)
%
% input file must contain the variables func, inputVars, outputFile
fprintf('Trying to evaluate %s\n', func2str(func))
try
    switch nargout(func)
        case 1            
            out = feval(func, inputVars{:});
        case 0
            feval(func, inputVars{:});
            out = 'no output';
            
    end
    outSize = whos('out');
    if outSize.bytes > 2*1024*1024*1024
        error(['Size of the output arguments must not exceed 2 GB. ', ...
            'For large data please save to disk in your function'])
    end
catch me
    display(me)
    out = me;
    
end

fprintf('Storing output in %s\n', outputFile)
save(outputFile, 'out', '-v6')

exit
