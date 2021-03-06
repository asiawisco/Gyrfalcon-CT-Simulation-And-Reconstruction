classdef SliceAnalysisRun
        
    properties
        volume = [];
        
        readPath = '';
        reconNumber = [];
        usedFloodFields = false;
        
        reconAlgorithm = ''; %'FDK' or 'OSC-TV'
        
        threshold = []
        writePath = ''
        
        sliceType = 'axial';
        sliceNum = 128;
        
        shifts = [0 0]; %vertical/horizontal shifts if needed for profiles
        
        lineStyle = '-';
        lineColor = [0 0 0];
        lineLabel = ''
    end
    
    methods
        function obj = readVolume(obj)
            switch obj.reconAlgorithm
                case 'FDK'
                    obj.volume = loadOpticalCtVistaRecon(obj.readPath);
                case 'OSC-TV'
                    [volumeOsctv, ~] = loadGyrfalconVolume(obj.readPath, obj.reconNumber, obj.usedFloodFields);
                    
                    % pad out the volume to 256x256x256
                    volume = zeros(256,256,256);
                    
                    volume(:,:,21:21+216-1) = volumeOsctv;
                    
                    obj.volume = volume;
            end
        end
        
        function [] = writeImages(obj)
            slice = obj.getSlice();
            
            % write png without an colourbar
            writeGrayscaleImage(...
                slice, obj.threshold,...
                strrep(obj.readPath, '.png', ' (1).png'));
            
            
        end
        
        function slice = getSlice(obj)
            switch obj.sliceType
                case 'axial'
                    slice = obj.volume(:,:,obj.sliceNum);
                otherwise
                    error('Unsupported!');
            end
                
        end
    end
    
end

