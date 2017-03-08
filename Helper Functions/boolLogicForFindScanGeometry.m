function scanGeometry = boolLogicForFindScanGeometry(simulation)
% scanGeometry = boolLogicForFindScanGeometry(simulation)

scanGeometry = [];

detector = simulation.detector;
scan = simulation.scan;
source = simulation.source;

isPencilBeam = false;
isFanBeam = false;
isConeBeam = false;

beamAngle = source.beamAngle;

xyAngle = beamAngle(1);
zAngle = beamAngle(2);

if xyAngle == 0
    if zAngle == 0
        isPencilBeam = true;
    else
        % fan beam, but in the z-direction
        errormsg('Simulation has a scan configuration with a fan-beam in the z-direction. This scan configuration cannot be reconstructed.');
    end
else
    if zAngle == 0
        isFanBeam = true;
    else
        isConeBeam = true;
    end
end

if source.isPointSource()
    detectorPlanar = detector.singleDetectorDimensions(1).isPlanar() && detector.singleDetectorDimensions(2).isPlanar();
    
    if isConeBeam
        detectorValid = detectorPlanar && detector.movesWithScanAngle && ~detector.movesWithPerAngleTranslation;
        
        scanValid = scan.perAngleTranslationDimensions(1) == 1 && scan.perAngleTranslationDimensions(2) == 1;
        
        if detectorValid && scanValid
            scanGeometry = ScanGeometries.ConeBeamCT;
        else
            if ~detectorValid
                errormsg('For a cone-beam reconstruction to be done, the detector used must be planar, move with the scan angle, and not move with per angle translations');
            end
            
            if ~scanValid
                errormsg('For a cone-beam reconstruction to be done, the scan used must not have any per angle translations for the source.');
            end
        end
    elseif isFanBeam
        detectorValid = detector.wholeDetectorDimensions(2) == 1;
        scanValid = scan.perAngleTranslationDimensions(2) == 1;
        
        if detectorValid && scanValid
            hasPerAngleTranslation = scan.perAngleTranslationDimensions(1) > 1;
            movesWithScanAngle = detector.movesWithScanAngle;
            movesWithPerAngle = detector.movesWithPerAngleTranslation;
            
            if hasPerAngleTranslation
                if movesWithScanAngle && movesWithPerAngle
                    scanGeometry = ScanGeometries.SecondGenCT;
                else
                    errormsg('For a 2nd Generation CT scan, the detector must move with the scan angle and per angle translations.');
                end
            else
                if ~movesWithPerAngle
                    if movesWithScanAngle
                        scanGeometry = ScanGeometries.ThirdGenCT;
                    elseif ~detectorPlanar
                        scanGeometry = ScanGeometries.FourthGenCT;
                    else
                        errormsg('Detector must be curved for 4th Generation CT scans.');
                    end
                else
                    errormsg('For a 3rd or 4th Generation CT scan, the detector must not move with per angle translations.');
                end
            end
        else
            if ~detectorValid
                errormsg('For a fan-beam CT scan, the detector must be 1D (no detectors in z-direction).');
            end
            
            if ~scanValid
                errormsg('For a fan-beam CT scan, the source must not have an per angle translation in the z-direction.');
            end
        end
    elseif isPencilBeam
        detectorValid = detectorPlanar && detector.wholeDetectorDimensions(2) == 1 && detector.movesWithScanAngle;
        scanValid = scan.perAngleTranslationDimensions(2) == 1;
        
        if detectorValid && scanValid
            scanGeometry = ScanGeometries.FirstGenCT;
        else
            if ~detectorValid
                errormsg('For a pencil-beam CT scan, the detector must be 1D, planar, and move with the scan angle.');
            end
            
            if ~scanValid
                errormsg('For a pencil-beam CT scan, the source must not have an per angle translation in the z-direction.');
            end
        end
    end
else
    errormsg('Simulation has a non-point source. This scan configuration cannot be reconstructed.');
end
end

