function state = get_final_status(jobid)
cmd = sprintf('scontrol -o show jobs  %u', jobid);

[result, output] = system_read_buffer_until_empty(cmd);

if result == 0 && ~isempty(output) 
    iJobState = strfind(output, 'JobState=');
    iNextSpace = strfind(output(iJobState:end), ' ');
    state = output(iJobState+9:iJobState+iNextSpace(1)-2);    
%     TODO: EndTime=2017-07-14T16:15:32
else 
    disp(output)
    error('Could not retreive job''s final status')
end
