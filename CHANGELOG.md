Changelog for `slurmfun`
=======================

[0.5] - 2020-05-15
------------------
* Changed 'mem' option to mean --mem-per-cpu for sbatch.
  It used to be --mem, which actually translates to 
  --mem-per-node/
* Memory reporting is now only valid for the cgroup plugin (bytes)
* The matlabcmd.sh script now defaults to MATLAB 2020a


[0.4] - 2020-05-11
------------------
* Added support for functions with multiple output arguments
* Re-added support for functions without output arguments

[0.3] - 2020-04-30
------------------
* Added `'cpu'` and `'mem'` options to configure number of cores and memory
  for each job
* Added option to specify a different partition for each job
* slurmfun now tolerates a SLURM controller outage of up to 5 min
* The MATLAB job can now be started with more than one thread
* Printing of progress has been improved
