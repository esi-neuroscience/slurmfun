%
% Parse partition specification
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function isValid = validate_partition(partition)

availablePartitions = get_available_partitions();

is_partition = @(x) ismember(x, availablePartitions);

if contains(partition,',')
    partition = regexp(partition,',','split');
end

if iscell(partition)
    isValid = all(cellfun(is_partition, partition));
elseif ischar(partition)
    isValid = is_partition(partition);
else
    error('partition must be a string or cell of string')
end


