#!/bin/bash

matlab='/mnt/hpx/opt/matlab-2020a/bin/matlab'
export HOME=/mnt/hpx/slurm/$SLURM_JOB_ACCOUNT

if [ ! -d "$HOME" ]; then
	mkdir $HOME
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
echo "Command: $1"
echo "---------------------------------------------------"
echo ""

srun $matlab -nodisplay -nosplash -r  "try $1; exit; catch exit; end"
