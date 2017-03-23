classdef FirstGenFilteredBackprojectionReconstruction < ProcessingRun
    % FirstGenFilteredBackprojectionReconstruction
    
    properties
        displayName = 'Filtered Backprojection'
        fullName = 'Filtered Backprojection (1st Gen)'
        
        filterType
    end
    
    methods
        
        function strings = getSettingsString(recon)
            strings = {'No Settings'};            
        end
        
        function [filterTypes, filterTypeStrings] = getFilterTypes(recon)
            [filterTypes, filterTypeStrings] = enumeration(FirstGenFilterTypes);
        end
        
    end
    
end
