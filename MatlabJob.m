classdef MatlabJob < handle
    
    properties
        id % SLURM job id                
        deleteFiles = true
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
                obj.update_state();
            end
        end
        
        function run_cmd(obj, cmd, partition, logFile, matlabBinary)
            [folder,~,~] = fileparts(logFile);
            baseCmd = sprintf(...
                'sbatch -A %s -D %s --gid=%u --parsable ', ...
                obj.userAccount, folder, obj.gid);
            cmd = sprintf('%s -p %s -o %s %s -m "%s" "%s"', ...
                baseCmd, partition, logFile, obj.matlabCaller, matlabBinary, cmd);
            [result, obj.id] = system_read_buffer_until_empty(cmd);                                
            assert(result == 0 || isempty(obj.id), 'Submission failed: %s\n', obj.id)
            obj.id = uint32(sscanf(obj.id,'%u'));
            obj.isComplete = false;
            obj.account = obj.userAccount;
            obj.logFile = logFile;
        end
            
        
        function update_state(obj)
            assert(~isempty([obj.id]), 'Undefined job id')
            jobInfo = sacct_query(obj.id);
            obj.duration = str2double(jobInfo.ElapsedRaw);
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
        
        function delete(obj)
            if ~strcmp(obj.userAccount, obj.account) && ~isempty(obj.id)
                warning('Not cancelling job %d as it belongs to %s', obj.id, obj.account)
                return
            end
            if ~obj.isComplete && ~isempty(obj.id)
                cmd = sprintf('scancel %u', obj.id);
                result = system(cmd);
                assert(result == 0, 'Could not cancel job %u', obj.id)
            end                                                
            
            if obj.deleteFiles
                warning('off', 'MATLAB:DELETE:FileNotFound')
                delete(obj.logFile)
                delete(obj.inputFile)
                delete(obj.outputFile)
                warning('on', 'MATLAB:DELETE:FileNotFound')
            end
        end
        
    end
end
