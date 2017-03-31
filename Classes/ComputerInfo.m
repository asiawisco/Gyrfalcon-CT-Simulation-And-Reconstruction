classdef ComputerInfo
    % ComputerInfo
    
    properties
        cpuType
        cpuClockSpeed
        cpuCacheSize
        cpuNumCores
        osType
        osVersion
        
        gpuDevice % MATLAB object
        
        userMemory
        systemMemory
        
        numCoresUsed
        gpuUsed
    end
    
    methods
        function info = ComputerInfo()
            tempInfo = cpuinfo();
            
            info.cpuType = tempInfo.Name;
            info.cpuClockSpeed = tempInfo.Clock;
            info.cpuCacheSize = tempInfo.Cache;
            info.cpuNumCores = tempInfo.NumProcessors;
            info.osType = tempInfo.OSType;
            info.osVersion = tempInfo.OSVersion;
            
            if parallelComputingToolboxInstalled()
                temp = struct(...
                    'computeCapability', gpuDevice.computeCapability...
                );
                
                info.gpuDevice = temp;
            else
                info.gpuDevice = [];
            end
            
            [user,system] = memory;
            
            info.userMemory = user;
            info.systemMemory = system;
        end
        
        function string = getSummaryString(info)
            str0 = 'Computer Information';
            
            str1 = ['OS: ', info.osType, ' (', info.osVersion, ')'];
            str2 = ['CPU Type: ', info.cpuType];
            str3 = ['CPU Clock Speed: ', info.cpuClockSpeed];
            str4 = ['CPU Cache Size: ', info.cpuCacheSize];
            str5 = ['# Cores Used: ', num2str(info.numCoresUsed), '/', num2str(info.cpuNumCores)];
            
            str6 = 'User Memory:';
            str7 = ['Max Possible Array Size: ', bytesToGbString(info.userMemory.MaxPossibleArrayBytes)];
            str8 = ['MATLAB Memory Usage: ', bytesToGbString(info.userMemory.MemUsedMATLAB), '/', bytesToGbString(info.userMemory.MemAvailableAllArrays)];
            
            str9 = 'System Memory:';
            str10 = ['Total Available: ', bytesToGbString(info.systemMemory.SystemMemory.Available)];
            str11 = ['Virtual Memory: ', bytesToGbString(info.systemMemory.VirtualAddressSpace.Available), '/', bytesToGbString(info.systemMemory.VirtualAddressSpace.Total)];
            str12 = ['Physical Memory: ', bytesToGbString(info.systemMemory.PhysicalMemory.Available), '/', bytesToGbString(info.systemMemory.PhysicalMemory.Total)];
            
            str13 = '';
            str14 = 'GPU Information';
            
            str15 = ['GPU Used: ', boolToYesNoString(info.gpuUsed)];
            
            string = {str0, str1, str2, str3, str4, str5, str6, str7, str8, str9, str10, str11, str12, str13, str14, str15};
            
            if isempty(info.gpuDevice)
                str16 = 'No GPU Device Installed';
                
                string = [string, {str16}];
            else
                str16 = ['Compute Capability: ', info.gpuDevice.computeCapability];
                
                string = [string, {str16}];
            end
        end
    end
    
end

function string = bytesToGbString(numBytes)
    numGb = numBytes ./ (1024^3);
    
    numGb = round(numGb*100)/100;
    
    string = [num2str(numGb),' Gb'];
end

function string = boolToYesNoString(bool)
    if bool
        string = 'Yes';
    else
        string = 'No';
    end
end
