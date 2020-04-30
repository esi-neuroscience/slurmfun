Changelog for `slurmfun`
=======================

[0.3] - 2020-04-30
------------------
* Added `'cpu'` and `'mem'` options to configure number of cores and memory
  for each job
* Added option to specify a different partition for each job
* slurmfun now tolerates a SLURM controller outage of up to 5 min
* The MATLAB job can now be started with more than one thread
* Printing of progress has been improved