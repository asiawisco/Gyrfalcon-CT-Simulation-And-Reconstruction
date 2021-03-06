classdef XrayCTImagingScan < ImagingScan
    % XrayCTImagingScan
    % This class contains all the data pertaining to an x-ray CT dataset
    % that is being imported into Gyrfalcon
    % 
    % FIELDS:
    % 
    % *ctScannerData
    % carries the data stored in the CT Scanner DICOMS
    
      
    
    
    properties
        ctScannerData       
    end
    
    methods
        function scan = XrayCTImagingScan()
            
        end
        
        function scan = createFromGUI(scan, app)
            
        end
        
        function app = setGUI(scan, app)
            app.ImagingScanTypeDropDown.Value = ImagingScanTypes.xrayCT;
            
            hideAllImagingScanImportSettingsTabs(app);
            app.XRayCTImportSettingsTab.Parent = app.ImportImagingScanTabGroup;
            
            % set fields
        end
        
        function imagingScan = importDataSet(imagingScan, seriesPath, targetDetectorDims, targetPixelDimsInM, savePath, saveFileName, vistaScannerData, usedRGBColours)
            % load Vista scanner data
            vistaScannerData = vistaScannerData.loadData(seriesPath);
            
            imagingScan.vistaScannerData = vistaScannerData;
            
            % load-up imaging scan objects (Detector, source, etc.)
            
            %DETECTOR
            detectorLocationInM = [0, vistaScannerData.getAxisToDetectorInM()];
            wholeDetectorDims = targetDetectorDims;
            singleDetectorDims = [Dimension(targetPixelDimsInM(1), Units.m), Dimension(targetPixelDimsInM(2), Units.m)];
            detectorMovesWithScanAngle = true;
            detectorMovesWithPerAngleTranslation = false;
            
            detector = Detector(...
                detectorLocationInM, wholeDetectorDims, singleDetectorDims,...
                detectorMovesWithScanAngle, detectorMovesWithPerAngleTranslation);
            
            %SOURCE
            sourceLocationInM = [0, -vistaScannerData.getAxisToSourceInM()];
            sourceDims = [Dimension(0, Units.m), Dimension(0, Units.m)]; % point source
            
            radiusInM = vistaScannerData.getAxisToSourceInM() + vistaScannerData.getAxisToDetectorInM();
            detectorDimsInM = detector.getSingleDetectorDimensionsInM();
            
            xyInM = detectorDimsInM(1) .* wholeDetectorDims(1) ./ 2;
            zInM = detectorDimsInM(2) .* wholeDetectorDims(2) ./ 2;
            
            beamAngleInDeg = 2 .* [atand(xyInM/radiusInM), atand(zInM/radiusInM)];
            
            source = Source(sourceLocationInM, sourceDims, beamAngleInDeg);
            
            %SCAN/BEAM CHARACTERIZATION
            angleSpacingInDeg = vistaScannerData.getAngleSpacingInDeg();
            
            scanAnglesInDeg = 0:angleSpacingInDeg:(vistaScannerData.getNumAngles()-1)*angleSpacingInDeg;
            
            slices = 0; % single slice at z=0
            
            perAngleTranslationDimensions = [1,1]; % single point
            perAngleTranslationResolution = [0,0]; % no movement
            
            numWavelengths = length(usedRGBColours);
            
            wavelengthsInNm = zeros(1,numWavelengths);
            
            for i=1:numWavelengths
                wavelengthsInNm(i) = usedRGBColours(i).wavelengthInNm;
            end
            
            intensities = ones(1,numWavelengths); % actual intensity is irrelevant, just relative intensity (RGB equal)
            
            beamCharacterization = OpticalPhotonBeam(wavelengthsInNm, intensities);
            
            scan = Scan(scanAnglesInDeg, slices,...
                perAngleTranslationDimensions, perAngleTranslationResolution,...
                beamCharacterization);
            
            % set imaging scan fields
            imagingScan.detector = detector;
            imagingScan.source = source;
            imagingScan.scan = scan;
            
            imagingScan.scanDateAndTime = vistaScannerData.getScanTimestamp();
            imagingScan.importDateAndTime = now();
            imagingScan.notes = notes;
        end
    end
end