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

while any(~[jobs.isFinalized]) && ~breakOut
    
    [activeIds, state] = get_active_jobs();
    
%     if isempty(runningIds) && any(~[jobs.isComplete])
%         nRunningEmpty = nRunningEmpty+1;
%         if nRunningEmpty > nRunningEmptyWarnThreshold
%             warning('Could not determine job status as the SLURM controller was not reachable for a while')                     
%         end
%         continue
%     end
    
    % write state of currently active jobs into job objects
    for iJob = 1:length(activeIds)
        jJob = find([jobs.id] == activeIds(iJob));
        if length(jJob) == 1
            jobs(jJob).state = state{iJob};
        end
    end
    
    notActive = ~ismember([jobs.id], activeIds);
    isActive = ismember([jobs.id], activeIds);
    
    if any(isActive)
        [jobs(isActive).isComplete] = deal(false);
    end
    if any(~isActive)
        [jobs(~isActive).isComplete] = deal(true);
    end
    
    iCompleteButNotFinalized = find(notActive & ~[jobs.isFinalized]);        
    
    % print current states
    [stateName, ~, idx] = unique({jobs.state});
    printString = sprintf('%16s : %6.1f min\n', 'Elapsed time', toc(tStart)/60);
    for iState = 1:length(stateName)
        printString = sprintf('%s%16s : %4d\n', printString, ...
            stateName{iState}, sum(idx==iState));
    end
    fprintf(printString)
    pause(10)

    
    if isempty(iCompleteButNotFinalized)
        fprintf(repmat('\b',1,length(printString)))
        continue
    end
    
    % limit to 500 jobs for sacct at once
    iCompleteButNotFinalized = iCompleteButNotFinalized(1:min([500,length(iCompleteButNotFinalized)]));
    
    % get stats of completed jobs
    jobInfo = sacct_query([jobs(iCompleteButNotFinalized).id]);
    fprintf(repmat('\b',1,length(printString)))
    
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
        
        switch state
            case 'COMPLETED'             
                               
            case 'RUNNING'
                jobs(jJob).isComplete = false;
                jobs(jJob).isFinalized = false;
            case {'FAILED','CANCELLED','TIMEOUT', 'OUT_OF_MEMORY'}
                fprintf('\n')
                [~, errorTail] = system_out_to_disk(['tail -n 5 ' jobs(jJob).logFile]);
                warning('An error occured in job %u (id %u).\n%s\nFull log: <a href="matlab: opentoline(''%s'',1)">%s</a>', ...
                    jJob, jobid, errorTail, jobs(jJob).logFile, jobs(jJob).logFile)
%                 fprintf(repmat(' ', 1,length(printString)-1));
                fprintf('\n')
                jobs(jJob).deleteFiles = false;
                if stopOnError
                    breakOut = true;
                    break
                else
                    
                end
            otherwise                
                disp(state)
                jobs(jJob).isComplete = false;
                jobs(jJob).isFinalized = false;
        end
        
        if mod(iJob, 20) == 0
            pause(0.001)
        end
    end              
    
end
