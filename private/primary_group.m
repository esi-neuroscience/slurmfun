function gid = primary_group()
[result, gid] = system_read_buffer_until_empty('id -g ');
if result == 0 
    gid = str2double(gid);
else
    error('Could not determine primary group of user');
end