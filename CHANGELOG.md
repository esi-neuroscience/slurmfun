 <!--
 Copyright (c) 2025 Ernst Strüngmann Institute (ESI) for Neuroscience
 in Cooperation with Max Planck Society
 SPDX-License-Identifier: CC-BY-NC-SA-1.0
 -->

# Changelog for `slurmfun`
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [2025.3]
First major update in a while adds support for the CoBIC HPC cluster and 
introduces a new convenience function as well as some code housekeeping. 

### NEW
- Added convenience function `show_jobs` to display status of currently active 
  jobs (mainly relevant if `slurmfun` was invoked with `waitForReturn` set to
  `false`)
- added tests for running `slurmfun` on the CoBIC HPC cluster
- include version information in MATLAB prompt and generated log files

### CHANGED
- Switched to date-based versioning

### REMOVED
- Removed `account` as input argument to `get_active_jobs`: it has not been used 
  anywhere in the package; instead a new (optional) input argument has been 
  introduced: `jobs`, an array of job ids or a `MatlabJob` array as returned by 
  slurmfun can be used to select which jobs to query. 
- Removed unused function `get_final_status`

### FIXED
- Do not assume a `/cs` filesystem exists on all clusters
- Updated and expanded tests

## [0.5] - 2020-05-15
- Changed 'mem' option to mean --mem-per-cpu for sbatch.
  It used to be --mem, which actually translates to 
  --mem-per-node/
- Memory reporting is now only valid for the cgroup plugin (bytes)
- The matlabcmd.sh script now defaults to MATLAB 2020a

## [0.4] - 2020-05-11
- Added support for functions with multiple output arguments
- Re-added support for functions without output arguments

## [0.3] - 2020-04-30
- Added `'cpu'` and `'mem'` options to configure number of cores and memory
  for each job
- Added option to specify a different partition for each job
- slurmfun now tolerates a SLURM controller outage of up to 5 min
- The MATLAB job can now be started with more than one thread
-Printing of progress has been improved
