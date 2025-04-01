# slurmfun

MATLAB tools for submitting jobs to the [SLURM workload manager](https://slurm.schedmd.com/overview.html). 

## Summary 

This repository provides tools for submitting MATLAB jobs to the SLURM scheduling 
system. The MATLAB function `slurmfun` can be used similar to the MATLAB function 
`cellfun`, i.e. it will apply a user-defined function to all elements of a cell 
array and return a cell array of output arguments. Each function call will be 
submitted as a separate job to the scheduler. See also `help slurmfun` for details.

## Cluster Environment
Up to now `slurmfun` has been used and tested in the cluster environments of the 
[Ernst Strüngmann Institute (ESI) gGmbH for Neuroscience in Cooperation with Max Planck Society](https://www.esi-frankfurt.de/) 
and the [Cooperative Brain Imaging Center](https://cobic.de/) comprising

- SLURM 17, 20.02, 20.11.9
- MATLAB 2014a up to 2024a
- Debian 8, RHEL 8.1-8.6

The default paths for log files and the SLURM working directory (`'slurmWorkingDirectory'`, `availableToolboxes` in `slurmfun.m`),  need to be adjusted for the specific 
cluster environment `slurmfun` is used in.

## Installation 

Clone this repository 

``` shell
git clone https://github.com/esi-neuroscience/slurmfun.git
```

and add it to your MATLAB path

``` matlab
addpath /path/to/slurmfun
```

## Usage 

Consider the function `myfunction` that generates a `in1`-by-`in2` matrix of uniformly 
distributed random numbers in the interval (0,1):

``` matlab
function out = myfunction(in1, in2)
out = rand(in1,in2);
```

To generate 5 matrices in parallel with `slurmfun` use, e.g., 

``` matlab
nJobs = 5;
inc1 = num2cell(randi(20, nJobs, 1) + 60);
inc2 = num2cell(randi(20, nJobs, 1) + 60);
[out, jobs] = slurmfun(@myfunction, inc1, inc2, 'partition', 'partitionName', 'mem', '7500M', 'cpu', 1);
```

A more elaborate example can be found in [Examples](./Examples), for a full list 
of options, use `help slurmfun`. 

## Contact and Support

To report bugs or ask questions please use our
[GitHub issue tracker](https://github.com/esi-neuroscience/slurmfun/issues).

## Project Status

This project is actively maintained and (sometimes) updated.
