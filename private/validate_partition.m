function isValid = validate_partition(partition)

availablePartitions = get_available_partitions();

is_partition = @(x) ischar(validatestring(x, availablePartitions));

if iscell(partition)
    isValid = all(cellfun(is_partition, partition));
else
    isValid = is_partition(partition);
end
    