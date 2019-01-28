function jobs = wait_for_jobs(jobs, stopOnError)
% WAIT_FOR_JOBS - Wait for completion of SLURM JOBS
% 
%       jobs = wait_for_jobs(jobs, stopOnError)
% 
% INPUT
% -----
%        jobs : array of job ids or MatlabJob array as returned by slurmfun
% stopOnError : boolean flag whether to interrupt if a job fails. Default
%               is true.
%   
% 
% OUTPUT
% ------
% 
%        jobs : MatlabJob array of completed jobs
% 

if isnumeric(jobs)
    jobIds = jobs;
    clear jobs
    jobs(1,length(jobIds)) = MatlabJob;
    for iJob = 1:length(jobs)
        jobs(iJob).id = jobIds(iJob);
        jobs(iJob).update_state()
    end           
end

nJobs = length(jobs);

if nargin < 2
    stopOnError = false;
end

fprintf('Waiting for jobs to complete\n')

tStart = tic;
breakOut = false;

printString = sprintf('PENDING/RUNNING jobs: %6d\nElapsed time: %6.1f min\n', ...
    sum(~[jobs.isComplete]), toc(tStart)/60);
fprintf(printString)


while any(~[jobs.isFinalized]) && ~breakOut
    pause(1)
    
    [ids, ~] = get_running_jobs();
    
    fprintf(repmat('\b',1,length(printString)));
    printString = sprintf('PENDING/RUNNING jobs: %6d\nElapsed time: %6.1f min\n', ...
        sum(~[jobs.isComplete]), toc(tStart)/60);
    fprintf(printString)

    notRunning = ~ismember([jobs.id], ids);
    isRunning = ismember([jobs.id], ids);
    
    if any(isRunning)
        [jobs(isRunning).isComplete] = deal(false);
    end
    if any(~isRunning)
        [jobs(~isRunning).isComplete] = deal(true);
    end
    
   
    iCompleteButNotFinalized = find(notRunning & ~[jobs.isFinalized]);        
    
    if isempty(iCompleteButNotFinalized)
        continue
    end
    
    % limit to 40 jobs for sacct at once
    iCompleteButNotFinalized = iCompleteButNotFinalized(1:min([40,length(iCompleteButNotFinalized)]));
    
    % get stats of completed jobs
    jobInfo = sacct_query([jobs(iCompleteButNotFinalized).id]);
    for iJob = 1:length(iCompleteButNotFinalized)
        
        jJob = iCompleteButNotFinalized(iJob);
        jobid = jobs(jJob).id;
        jobs(jJob).isFinalized = true;
        jobs(jJob).readFromDisk = jobInfo(iJob).MaxDiskRead;
        jobs(jJob).wroteToDisk = jobInfo(iJob).MaxDiskWrite;
        jobs(jJob).duration = str2double(jobInfo(iJob).ElapsedRaw);
        jobs(jJob).memoryUsed = jobInfo(iJob).MaxVMSize;
        
        state = strtok(jobInfo(iJob).State);
        jobs(jJob).state = state;
%         jobs(jJob).update_state()
        
        
        switch state
            case 'COMPLETED'             
                
                
            case 'RUNNING'
                jobs(jJob).isComplete = false;
                jobs(jJob).isFinalized = false;
            case {'FAILED','CANCELLED','TIMEOUT'}
                fprintf('\n')
                [~, errorTail] = system_out_to_disk(['tail -n 5 ' jobs(jJob).logFile]);
                warning('An error occured in job %u (id %u).\n%s\nFull log: <a href="matlab: opentoline(''%s'',1)">%s</a>', ...
                    jJob, jobid, errorTail, jobs(jJob).logFile, jobs(jJob).logFile)
                fprintf(repmat(' ', 1,length(printString)-1));
                fprintf('\n')
                jobs(jJob).deleteFiles = false;
                if stopOnError
                    breakOut = true;
                    break
                end
            otherwise                
                disp(state)
                jobs(jJob).isComplete = false;
                jobs(jJob).isFinalized = false;
        end
        pause(0.001)
    end              
end
