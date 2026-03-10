#!/usr/bin/env bash
#
# Helper script for executing MATLAB commands inside sbatch
#
# Copyright © 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
# in Cooperation with Max Planck Society
# Copyright © 2026 Ernst Strüngmann Institute (ESI) of the Max Planck Society
#
# SPDX-License-Identifier: BSD-3-Clause
#

if [[ "${HOSTNAME}" == esi-svhpc* ]]; then
    matlab='/cs/opt/matlab-2020b/bin/matlab'
    export HOME=/cs/slurm/$SLURM_JOB_ACCOUNT
    if [ ! -d "$HOME" ]; then
        mkdir $HOME
    fi
fi

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        -m|--matlab)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                matlab=$2
                shift
            else
                die 'ERROR: "--matlab" requires a non-empty option argument.'
            fi
            ;;
        -v|--version)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                version=$2
                shift
            else
                die 'ERROR: "--version" requires a non-empty option argument.'
            fi
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

echo "---------------------------------------------------"
echo "Job: $SLURM_JOB_ID"
echo "Partition: $SLURM_JOB_PARTITION"
echo "Account: $SLURM_JOB_ACCOUNT"
echo "Node: $SLURMD_NODENAME"
echo "Job start time: `date`"
echo "MATLAB: $matlab"
if [ -n ${version+x} ]; then
    echo "Version of slurmfun: ${version}"
fi
echo "Environment: $(env)"
echo "Command: $1"
echo "---------------------------------------------------"
echo ""

# Prevent running AVX2 code on older Intel CPUs
lscpu | grep -q avx2 || export MKL_ENABLE_INSTRUCTIONS=AVX

srun $matlab -nodisplay -nosplash -r  "try $1; exit; catch exit; end"
