%
% Query SLURM partitions
%
% Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
% in Cooperation with Max Planck Society
%
% SPDX-License-Identifier: BSD-3-Clause
%
function [availablePartitions, defaultPartition] = get_available_partitions()
% AVAILABLE_PARTITIONS - Retreive partitions avilable in SLURM
% 
[result, availablePartitions] = system_read_buffer_until_empty('sinfo -h -o %P');
assert(result == 0, 'Could not receive available SLURM partitions using sinfo');
availablePartitions = strsplit(availablePartitions);
availablePartitions(cellfun(@isempty, availablePartitions)) = '';
defaultPartition = ~cellfun(@isempty, strfind(availablePartitions, '*'));
assert(sum(defaultPartition) == 1, 'Multiple default partitions found (contain * in name).')
availablePartitions = strrep(availablePartitions, '*', '');
defaultPartition = availablePartitions(defaultPartition);
