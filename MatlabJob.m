classdef MatlabJob < handle
    
    properties
        id % SLURM job id                
        deleteLogfile = true
        state
        memoryUsed
        readFromDisk
        wroteToDisk
        duration        
        logFile
        partition
        account
        isComplete = false
        isFinalized = false
        inputFile 
        outputFile
    end
    
    
    
    properties ( Constant = true, Access = private )
        userAccount = getenv('USER');
        gid = primary_group();
        matlabCaller = fullfile(fileparts(mfilename('fullpath')), 'matlabcmd.sh');
    end
    
    methods
        function obj = MatlabJob(cmd, varargin)
            if nargin == 0
                return
            end
            if ischar(cmd)
                obj.run_cmd(cmd, varargin{:})
            elseif isnumeric(cmd) && numel(cmd) == 1
                obj.id = cmd;
                obj.sacct_query();
            end
        end
        
        function run_cmd(obj, cmd, partition, logFile, matlabBinary)
            [folder,~,~] = fileparts(logFile);
            baseCmd = sprintf(...
                'sbatch -A %s -D %s --uid=slurm --gid=%u --parsable ', ...
                obj.userAccount, folder, obj.gid);
            cmd = sprintf('%s -p %s -o %s %s -m "%s" "%s"', ...
                baseCmd, partition, logFile, obj.matlabCaller, matlabBinary, cmd);
            [result, obj.id] = system(cmd);
            % workaround for MATLAB bug: https://www.mathworks.com/support/bugreports/1400063
            [~,remainder] = system('');
            obj.id = [obj.id remainder];
            assert(result == 0 || isempty(obj.id), 'Submission failed: %s\n', obj.id)
            obj.id = uint32(sscanf(obj.id,'%u'));
            obj.isComplete = false;
            
            obj.logFile = logFile;
        end
            
        
        function sacct_query(obj)
            assert(~isempty(obj.id), 'Undefined job id')
            jobInfo = sacct_query(obj.id);
            obj.duration = jobInfo.Elapsed;
            obj.partition = jobInfo.Partition;
            obj.state = jobInfo.State;
            obj.memoryUsed = jobInfo.MaxRSS;
            obj.account = jobInfo.Account;
            obj.readFromDisk = jobInfo.MaxDiskRead;
            obj.wroteToDisk = jobInfo.MaxDiskWrite;
            if ismember(obj.state, {'RUNNING', 'PENDING', 'RESIZING', 'REQUEUED'})
                obj.isComplete = false;
            else
                obj.isComplete = true;
            end
            
        end
        
        function clean(obj)
            if ~strcmp(obj.userAccount, obj.account)
                warning('Not cancelling job %d as it belongs to %s', obj.id, obj.account)
                return
            end
            if ismember(obj.state, {' RUNNING', 'PENDING', 'RESIZING', 'REQUEUED'})
                cmd = sprintf('scancel %u', obj.id);
                result = system(cmd);
                assert(result == 0, 'Could not cancel job %u', obj.id)
            end
            
            if obj.deleteLogfile
                delete(obj.logFile)
            end
        end
        
    end
end
