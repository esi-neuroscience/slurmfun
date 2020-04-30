function isValid = validate_partition(partition)

availablePartitions = get_available_partitions();

is_partition = @(x) ismember(x, availablePartitions);

if iscell(partition)
    isValid = all(cellfun(is_partition, partition));
elseif ischar(partition)
    isValid = is_partition(partition);
else
    error('partition must be a string or cell of string')
end


    