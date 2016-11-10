classdef Scan
    % Scan
    % This class contains all the data pertaining to an CT scan
    % 
    % FIELDS:
    % *scanAngles:
    % the angles at which the source (and detector in some cases)
    % will go to during the duration of the scan
    % [0,45,90,135,180,225,270,315]
    %
    % *slices: 
    % the positions in the z (slice) direction that the gantry will go to
    % [0,1,2,3]
    % units are in mm
    %
    % *perAngleTranslationDimensions:
    % the dimensions that the source/detector should translate with at each
    % angle the gantry moves too
    % [transverse, depth]
    % units are in m
    %
    % *perAngleTranslationResolution:
    % the step-size that is used to transverse the above 
    % perAngleTranslationDimesion
    % [transverse, depth]
    % units are in m
    %
    % *beamCharacterization:
    % an aray of PhotonBeam data structures, that describe the
    % total overall beam being used in imaging. Use {singleEnergyBeam} for
    % a single energy beam
    % [photonBeam1, photonBeam2, photonBeam3]
    
    
    
    properties
        scanAngles
        scanAngleUnits = Units.degree
        
        slices
        sliceUnits = Units.mm
        
        perAngleTranslationDimensions
        perAngleTranslationResolution
        perAngleTranslationUnits = Units.mm
        
        beamCharacterization
        
        beamCharacterizationPath
        beamCharacterizationFileName
        
        savePath
        saveFileName
    end
    
    methods
        function scan = Scan(scanAngles, slices, perAngleTranslationDimensions, perAngleTranslationResolution, beamCharacterization)
            if nargin > 0
                % validate scan parameters and fill in blanks if needed
                
                % validate scanAngles
                % no validation
                
                % validate slices
                % no validation
                
                % validate perAngleTranslationDimensions
                perAngleTranslationDimensionsNumDims = length(perAngleTranslationDimensions);
                
                if perAngleTranslationDimensionsNumDims < 1 || perAngleTranslationDimensionsNumDims > 2
                    error('Translation Dimensions not given in 1 or 2 space');
                elseif perAngleTranslationDimensionsNumDims == 1
                    % make depth measurement as 0
                    
                    perAngleTranslationDimensions = [perAngleTranslationDimensions, 0];
                end
                
                % validate perAngleTranslationResolution
                perAngleTranslationResolutionNumDims = length(perAngleTranslationResolution);
                
                if perAngleTranslationResolutionNumDims < 1 || perAngleTranslationResolutionNumDims > 2
                    error('Translation Resolution not given in 1 or 2 space');
                elseif perAngleTranslationResolutionNumDims == 1
                    % make depth resolution as 0
                    
                    perAngleTranslationResolution = [perAngleTranslationResolution, 0];
                end
                
                if perAngleTranslationDimensionsNumDims ~= perAngleTranslationResolutionNumDims
                    error('Translation Dimensions and Resolution dimensionality are not consistent');
                end
                
                % validate beamCharacterization
                % no validation
                
                % if we get here, we're good to go, so lets assign the fields
                scan.scanAngles = scanAngles;
                scan.slices = slices;
                scan.perAngleTranslationDimensions = perAngleTranslationDimensions;
                scan.perAngleTranslationResolution = perAngleTranslationResolution;
                scan.beamCharacterization = beamCharacterization;
            end
        end
        
        function slicesInM = getSlicesInM(scan)
            slices = scan.slices;
            units = scan.sliceUnits;
            
            slicesInM = units.convertToM(slices);
        end
        
        function anglesInDegrees = getScanAnglesInDegrees(scan)
            angles = scan.scanAngles;
            units = scan.scanAngleUnits;
            
            anglesInDegrees = units.convertToDegrees(angles);
        end
        
        function [perAngleXYInM, perAngleZInM] = getPerAnglePositionInM(scan, xyStep, zStep)
            units = scan.perAngleTranslationUnits;
            
            totalNumXYSteps = scan.perAngleTranslationDimensions(1);
            totalNumZSteps = scan.perAngleTranslationDimensions(2);
            
            midXYStep = (totalNumXYSteps + 1) / 2;
            midZStep = (totalNumZSteps + 1) / 2;
            
            xyPos = (xyStep - midXYStep) * scan.perAngleTranslationResolution(1);
            zPos = (zStep - midZStep) * scan.perAngleTranslationResolution(2);
            
            perAngleXYInM = units.convertToM(xyPos);
            perAngleZInM = units.convertToM(zPos);
        end
        
        function [] = plot(scan, source, axesHandle)
            locationInM = source.locationUnits.convertToM(source.location);
                        
            x = locationInM(1);
            y = locationInM(2);
            z = locationInM(3);
            
            [theta,radius] = cart2pol(x,y);                
            theta = theta * Constants.rad_to_deg; % this angle is base angle to rotate to, and then add more for scan angles
                        
            scanAngles = scan.scanAngleUnits.convertToDegrees(scan.scanAngles);
            
            numAngles = length(scanAngles);
            
            for i=1:numAngles
                angle = scanAngles(i);
                
                if mod(angle, 360) ~= 0 %make sure not a starting location
                    % get (x,y) for source at this point
                    thetaRad = (theta - angle) * Constants.deg_to_rad; % NOTE: use -, because we define + angle as clockwise, polar coords are opposite
                    
                    [x1,y1] = pol2cart(thetaRad, radius);
                    
                    % plot where source will be
                    edgeColour = Constants.Source_Colour;
                    faceColour = []; % hollow it out
                    lineStyle = [];
                    lineWidth = [];
                    
                    circleOrArcPatch(...
                        x1,y1,z,Constants.Point_Source_Radius, 0, 360,...
                        edgeColour, faceColour, lineStyle, lineWidth);
                    
                    x2 = -x1; %line goes across circle
                    y2 = -y1;
                    
                    x = [x1,x2];
                    y = [y1,y2];
                    
                    line(x,y,'Parent', axesHandle, 'Color', Constants.Source_Colour, 'LineStyle', '--');
                end
            end
            
            % plot slices
            slicesInM = scan.sliceUnits.convertToM(scan.slices);
            
            numSlices = length(slicesInM);
            
            % slice vars
            x = 0;
            y = 0; % at origin
            r = radius; % found above
            ang1 = 0;
            ang2 = 360; % to make circle
            
            edgeColour = Constants.Slice_Colour;
            faceColour = 'none';
            lineStyle = '--';
            lineWidth = [];
            
            for i=1:numSlices
                z = slicesInM(i);
                    
                if z ~= locationInM(3) % don't draw circle where the detector starts                    
                    circleOrArcPatch(x, y, z, r, ang1, ang2, edgeColour, faceColour, lineStyle, lineWidth);
                end
            end
            
            % per angle translation plotting
            translationResolutionInM = scan.perAngleTranslationUnits.convertToM(scan.perAngleTranslationResolution);
            
            x = locationInM(1);
            y = locationInM(2);
            z = locationInM(3);
            
            [theta,radius] = cart2pol(x,y);                
            theta = theta * Constants.rad_to_deg;
            
            aboutZ = [0,0,1];
            
            xyResolution = translationResolutionInM(1);
            zResolution = translationResolutionInM(2);
            
            xyNumSteps = scan.perAngleTranslationDimensions(1);
            zNumSteps = scan.perAngleTranslationDimensions(2);
            
            if xyNumSteps ~= 0
                xyNumSteps = xyNumSteps - 1;
            end
            
            if zNumSteps ~= 0
                zNumSteps = zNumSteps - 1;
            end
            
            xyStart = -xyResolution*(xyNumSteps/2);
            xyEnd = xyResolution*(xyNumSteps/2);
            
            zStart = z-(zNumSteps/2)*zResolution;
            zEnd = z+(zNumSteps/2)*zResolution;
            
            lineColour = Constants.Per_Angle_Translation_Colour;
            
            if xyStart == xyEnd % draw line along z
                
                line([x,x],[y,y],[zStart,zEnd],'Color',lineColour);
                
                for zVal=zStart:zResolution:zEnd
                    y1 = y - Constants.Per_Angle_Translation_Tick_Length;
                    y2 = y + Constants.Per_Angle_Translation_Tick_Length;
                    
                    lineHandle = line([x,x],[y1,y2],[zVal,zVal],'Color',lineColour);
                    
                    origin = [x, y, zVal];
                    
                    rotate(lineHandle, aboutZ, theta, origin);
                end
            else
                for zVal=zStart:zResolution:zEnd
                    lineHandle = line([radius,radius],[xyStart,xyEnd],[zVal,zVal],'Color',lineColour);
                    
                    rotate(lineHandle, aboutZ, theta);
                    
                    for xyVal=xyStart:xyResolution:xyEnd
                        z1 = zVal - Constants.Per_Angle_Translation_Tick_Length;
                        z2 = zVal + Constants.Per_Angle_Translation_Tick_Length;
                        
                        lineHandle = line([radius,radius],[xyVal,xyVal],[z1,z2],'Color',lineColour);
                                                
                        rotate(lineHandle, aboutZ, theta);
                    end
                end
            end
                          
        end
        
        function handles = setGUI(scan, handles)
            setMultipleDoublesForHandle(handles.scanAnglesEdit, scan.scanAngles);
            setMultipleDoublesForHandle(handles.scanSlicePositionsEdit, scan.slices);
            
            xy = scan.perAngleTranslationDimensions(1);
            z = scan.perAngleTranslationDimensions(2);
            
            setDoubleForHandle(handles.scanPerAngleTranslationStepsXYEdit, xy);
            setDoubleForHandle(handles.scanPerAngleTranslationStepsZEdit, z);
            
            xy = scan.perAngleTranslationResolution(1);
            z = scan.perAngleTranslationResolution(2);
            
            setDoubleForHandle(handles.scanPerAngleStepDimensionsXYEdit, xy);
            setDoubleForHandle(handles.scanPerAngleStepDimensionsZEdit, z);
            
            handles.scanBeamCharacterization = scan.beamCharacterization; % TODO!
            
            if ~isempty(scan.beamCharacterizationFileName)
                setString(handles.scanBeamCharacterizationFileNameText, scan.beamCharacterizationFileName);
            end
                        
            if isempty(scan.saveFileName)
                setString(handles.scanFileNameText, 'Not Saved');
            else
                setString(handles.scanFileNameText, scan.saveFileName);
            end
            
            % set hidden handles
            handles.scanSavePath = scan.savePath;
            handles.scanSaveFileName = scan.saveFileName;
            
            handles.scanBeamCharacterizationPath = scan.beamCharacterizationPath;
            handles.scanBeamCharacterizationFileName = scan.beamCharacterizationFileName;
        end
        
        function scan = createFromGUI(scan, handles)
            scan.scanAngles = getMultipleDoublesFromHandle(handles.scanAnglesEdit);
            scan.slices = getMultipleDoublesFromHandle(handles.scanSlicePositionsEdit);
            
            xy = getDoubleFromHandle(handles.scanPerAngleTranslationStepsXYEdit);
            z = getDoubleFromHandle(handles.scanPerAngleTranslationStepsZEdit);
            
            scan.perAngleTranslationDimensions = [xy, z];
            
            xy = getDoubleFromHandle(handles.scanPerAngleStepDimensionsXYEdit);
            z = getDoubleFromHandle(handles.scanPerAngleStepDimensionsZEdit);
            
            scan.perAngleTranslationResolution = [xy, z];
            
            % TODO!
            beamEnergy = 175; %in kEv
            beamIntensity = 30; %in w/m^2
            
            photonBeam = PhotonBeam(beamEnergy, beamIntensity);
            
            handles.scanBeamCharacterization = {photonBeam};
            
            scan.beamCharacterization = handles.scanBeamCharacterization;
            % TODO!
            
            scan.beamCharacterizationPath = handles.scanBeamCharacterizationPath;
            scan.beamCharacterizationFileName = handles.scanBeamCharacterizationFileName;
            
            
            scan.savePath = handles.scanSavePath;
            scan.saveFileName = handles.scanSaveFileName;
        end
        
    end
    
end

