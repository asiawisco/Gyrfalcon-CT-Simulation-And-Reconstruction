classdef Detector
    % Detector
    % This class contains all the data pertaining to an x-ray detector for the CT
    % simulator.
    %
    % FIELDS:
    % *location:
    % the location where the centre of the detector will begin for a
    % simulated scan. The detector is assumed to be symmetrical around its
    % centre
    % units are in m
    %
    % *wholeDetectorDimensions:
    % the number of detectors that make up the whole detector, and in each
    % direction
    % [# in width, # in depth]
    %
    % *singleDetectorDimensions:
    % the dimensions of a single detector that will make up the whole
    % detector
    % units are in mm or degrees
    %
    % *detectorMovesWithSource:
    % boolean field that determines whether the detector moves with the
    % radiation source or not
    
    
    
    properties
        location
        locationUnits = Units.m
        
        wholeDetectorDimensions
        singleDetectorDimensions
        movesWithSource
        
        savePath
        saveFileName
    end
    
    methods
        function detector = Detector(location, wholeDetectorDimensions, singleDetectorDimensions, detectorMovesWithSource)
            if nargin > 0
                % validate detector parameters and fill in blanks if needed
                
                % validate location
                locationNumDims = length(location);
                
                if locationNumDims < 2 || locationNumDims > 3
                    error('Location of detector not given in 2 or 3 space');
                elseif locationNumDims == 2
                    % tack on z = 0 for completeness
                    
                    location = [location, 0];
                end
                
                % validate wholeDetectorDimensions
                wholeDetectorNumDims = length(wholeDetectorDimensions);
                
                if wholeDetectorNumDims < 1 || wholeDetectorNumDims > 2
                    error('Whole detector dimensions not given in 1 or 2 space');
                elseif wholeDetectorNumDims == 1
                    % take on depth = 1 for completeness
                    
                    wholeDetectorDimensions = [wholeDetectorDimensions, 1];
                end
                
                % singleDetectorDimensions
                singleDetectorNumDims = length(singleDetectorDimensions);
                
                if singleDetectorNumDims < 1 || singleDetectorNumDims > 2
                    error('Single dectector dimensions not given in 1 or 2 space');
                elseif singleDetectorNumDims == 1
                    % make depth measurement as 0, planar
                    
                    value = 0;
                    isPlanar = true;
                    
                    singleDetectorDimensions = [singleDetectorDimensions, Dimension(value, isPlanar)];
                end
                
                % if we get here, we're good to go, so lets assign the fields
                detector.location = location;
                detector.wholeDetectorDimensions = wholeDetectorDimensions;
                detector.singleDetectorDimensions = singleDetectorDimensions;
                detector.movesWithSource = detectorMovesWithSource;
            end
        end
        
        function locationInM = getLocationInM(detector)
            units = detector.locationUnits;
            location = detector.location;
            
            locationInM = units.convertToM(location);            
        end
        
        function position = getDetectorPosition(detector, slicePosition, scanAngle)
            location = detector.getLocationInM();
            
            z = slicePosition;
            
            if detector.movesWithSource
                [theta, radius] = cart2pol(location(1), location(2));
                theta = theta * Constants.rad_to_deg;
                
                detectorAngle = theta - scanAngle; %minus because we define scanAngle to be clockwise, but Matlab is counter-clockwise
                
                [x,y] = pol2cart(detectorAngle * Constants.deg_to_rad, radius);
            else
                x = location(1);
                y = location(2);
            end
            
            position = [x,y,z];
        end
        
        function [] = plot(detector, axesHandle)
            locationInM = detector.locationUnits.convertToM(detector.location);
            
            singleDimensions = detector.singleDetectorDimensions;
            wholeDimensions = detector.wholeDetectorDimensions;
            
            detectorLineHeight = getDetectorLineHeight(detector);
            
            if false %singleDimensions(1).units.isAngular %curved
                detectorAngle = singleDimensions(1).getAngleInDegrees();
                
                totalAngle = detectorAngle * wholeDimensions(1);
                
                ang1 = -totalAngle/2;
                ang2 = totalAngle/2;
                
                x = 0;
                y = 0;
                z = 0;
                
                rTop = norm(locationInM);
                rBottom = rTop + detectorLineHeight;
                
                edgeColour = Constants.Detector_Colour;
                faceColour = 'none';
                lineStyle = [];
                lineWidth = [];
                
                topArcHandle = circleOrArcPatch(x, y, z, rTop, ang1, ang2, edgeColour, faceColour, lineStyle, lineWidth);
                botArcHandle = circleOrArcPatch(x, y, z, rBottom, ang1, ang2, edgeColour, faceColour, lineStyle, lineWidth);
                
                set(topArcHandle, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
                set(botArcHandle, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
                
                detectorLineHandles = {};
                
                aboutZ = [0,0,1];
                
                count = 0;
                
                for i=-wholeDimensions(1)/2:wholeDimensions(1)/2
                    x = [rTop, rBottom];
                    y = [0, 0];
                    z = [0, 0];
                    
                    lineHandle = line(x, y, z, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
                    
                    rotate(lineHandle, aboutZ, detectorAngle(1)*i);
                    
                    count = count + 1;
                    
                    detectorLineHandles{count} = lineHandle;
                end
                
                [theta,~] = cart2pol(locationInM(1),locationInM(2));
                
                % now rotate, first get angle to rotate
                rotate(topArcHandle, aboutZ, rad2deg(theta));
                rotate(botArcHandle, aboutZ, rad2deg(theta));
                
                for i=1:count
                    rotate(detectorLineHandles{i}, aboutZ, rad2deg(theta));
                end
            else % not curved
                % graphic properities
                edgeColour = Constants.Detector_Colour;
                backEdgeColour = Constants.Detector_Back_Colour;
                
                faceColour = 'none';
                lineStyle = '-';
                lineWidth = [];
                
                % need these axis to rotate around
                aboutX = [1,0,0];
                aboutY = [0,1,0];
                aboutZ = [0,0,1];
                
                % xy rotation angle
                [theta, ~] = cart2pol(locationInM(1), locationInM(2));
                rotAngle = theta * Constants.rad_to_deg;
                
                % prepping angles and length
                xyIsAngular = singleDimensions(1).units.isAngular;
                zIsAngular = singleDimensions(2).units.isAngular;                
                
                if xyIsAngular
                    xyAngle = singleDimensions(1).getAngleInDegrees() * wholeDimensions(1);
                else
                    xyLength = singleDimensions(1).getLengthInM() * wholeDimensions(1);
                end
                
                if zIsAngular
                    zAngle = singleDimensions(2).getAngleInDegrees() * wholeDimensions(2);
                else
                    zLength = singleDimensions(2).getLengthInM() * wholeDimensions(2);
                end
                
                radius = norm([locationInM(1), locationInM(2)]); % get x,y norm
                
                % *****************************************************
                % plot xyLines as vertical line at x = radius, and then
                % rotate into correct position
                
                xyLines_top_x = [radius, radius];
                xyLines_bot_x = [radius + detectorLineHeight, radius + detectorLineHeight];
                
                if ~xyIsAngular
                    xyLines_y = [-xyLength/2, xyLength/2];
                end
                
                if zIsAngular
                    if zAngle == 0
                        xyLines_z_vals = locationInM(3);
                    else
                        xyLines_z_vals =  -zAngle/2 : singleDimensions(2).getAngleInDegrees() : zAngle/2;
                    end
                else
                    if zLength == 0
                        xyLines_z_vals = locationInM(3);
                    else
                        xyLines_z_vals = locationInM(3) - (zLength/2) : singleDimensions(2).getLengthInM() : locationInM(3) + (zLength/2);
                    end
                end
                
                for i=1:length(xyLines_z_vals)
                    xyLines_z = xyLines_z_vals(i);
                                        
                    if xyIsAngular
                        x = 0;
                        y = 0;
                        
                        topR = radius;
                        botR = radius + detectorLineHeight;
                        
                        if zIsAngular
                            z = 0;
                            
                            theta = xyLines_z;
                            psi = xyAngle/2;
                            arcRadius = topR;
                            
                            top_ang1 = findAngleForPerpendicularArc(theta, psi, arcRadius);
                            top_ang2 = -top_ang1;
                            
                            arcRadius = botR;
                                                        
                            bot_ang1 = findAngleForPerpendicularArc(theta, psi, arcRadius);
                            bot_ang2 = -bot_ang1;
                        else
                            z = xyLines_z;
                            
                            top_ang1 = (-xyAngle/2);
                            top_ang2 = (xyAngle/2);
                            
                            bot_ang1 = (-xyAngle/2);
                            bot_ang2 = (xyAngle/2);
                        end
                       
                        topLineHandle = circleOrArcPatch(x, y, z, topR, top_ang1, top_ang2, edgeColour, faceColour, lineStyle, lineWidth);
                        botLineHandle = circleOrArcPatch(x, y, z, botR, bot_ang1, bot_ang2, backEdgeColour, faceColour, lineStyle, lineWidth);
                        
                        if zIsAngular % rotate about y to get them in position
                            rotate(topLineHandle, aboutY, xyLines_z);
                            rotate(botLineHandle, aboutY, xyLines_z);
                        end
                    else
                        topX = xyLines_top_x;
                        botX = xyLines_bot_x;
                        
                        y = xyLines_y;
                        
                        if zIsAngular
                            z = [0,0];
                        else
                            z = [xyLines_z, xyLines_z];
                        end
                    
                        topLineHandle = line(topX, y, z, 'Parent', axesHandle, 'Color', edgeColour);
                        botLineHandle = line(botX, y, z, 'Parent', axesHandle, 'Color', backEdgeColour);
                        
                        if zIsAngular % rotate about y to get them in position
                            rotate(topLineHandle, aboutY, xyLines_z);
                            rotate(botLineHandle, aboutY, xyLines_z);
                        end
                    end
                    
                    % rotate so that middle is at start point
                    rotate(topLineHandle, aboutZ, rotAngle);
                    rotate(botLineHandle, aboutZ, rotAngle);
                end
                
                % *****************************************************
                % plot zLines as z direction line a x = radius,
                % and then rotate into correct position
                
                xyLines_top_x = [radius, radius];
                xyLines_bot_x = [radius + detectorLineHeight, radius + detectorLineHeight];
                                
                if xyIsAngular
                    if xyAngle == 0
                        xyLines_y_vals = 0;
                    else
                        xyLines_y_vals =  -xyAngle/2 : singleDimensions(1).getAngleInDegrees() : xyAngle/2;
                    end
                else
                    if xyLength == 0
                        xyLines_y_vals = 0;
                    else
                        xyLines_y_vals =  -(xyLength/2) : singleDimensions(1).getLengthInM() : (xyLength/2);
                    end
                end
                
                
                if ~zIsAngular
                    xyLines_z = [locationInM(3) - zLength/2, locationInM(3) + zLength/2];
                end
                
                for i=1:length(xyLines_y_vals)
                    xyLines_y = xyLines_y_vals(i);
                                        
                    if zIsAngular
                        x = 0;
                        z = 0;
                        
                        topR = radius;
                        botR = radius + detectorLineHeight;
                        
                        if xyIsAngular
                            y = 0;
                            
                            theta = xyLines_y;
                            psi = zAngle/2;
                            arcRadius = topR;
                            
                            top_ang1 = findAngleForPerpendicularArc(theta, psi, arcRadius);
                            top_ang2 = -top_ang1;
                            
                            arcRadius = botR;
                                                        
                            bot_ang1 = findAngleForPerpendicularArc(theta, psi, arcRadius);
                            bot_ang2 = -bot_ang1;                            
                        else
                            y = xyLines_y;
                            
                            top_ang1 = (-zAngle/2);
                            top_ang2 = (zAngle/2);
                            
                            bot_ang1 = (-zAngle/2);
                            bot_ang2 = (zAngle/2);
                        end
                        
                        
                        topLineHandle = circleOrArcPatch(x, y, z, topR, top_ang1, top_ang2, edgeColour, faceColour, lineStyle, lineWidth);
                        botLineHandle = circleOrArcPatch(x, y, z, botR, bot_ang1, bot_ang2, backEdgeColour, faceColour, lineStyle, lineWidth);
                        
                        % since angle in xy, rotate 90 about x
                        origin = [x,y,z];
                        
                        rotate(topLineHandle, aboutX, 90, origin);
                        rotate(botLineHandle, aboutX, 90, origin);
                        
                        if xyIsAngular % rotate about y to get them in position
                            rotate(topLineHandle, aboutZ, xyLines_y);
                            rotate(botLineHandle, aboutZ, xyLines_y);
                        end
                    else
                        topX = xyLines_top_x;
                        botX = xyLines_bot_x;
                                                
                        if xyIsAngular
                            y = [0,0];
                        else
                            y = [xyLines_y, xyLines_y];
                        end
                                                
                        z = xyLines_z;
                    
                        topLineHandle = line(topX, y, z, 'Parent', axesHandle, 'Color', edgeColour);
                        botLineHandle = line(botX, y, z, 'Parent', axesHandle, 'Color', backEdgeColour);
                        
                        if xyIsAngular % rotate about y to get them in position
                            rotate(topLineHandle, aboutZ, xyLines_y);
                            rotate(botLineHandle, aboutZ, xyLines_y);
                        end
                    end
                    
                    % rotate so that middle is at start point
                    rotate(topLineHandle, aboutZ, rotAngle);
                    rotate(botLineHandle, aboutZ, rotAngle);
                end
                
                
                
                
                
                
                
                
                
                
                
                
                
                
%                 xyLines_x = [radius, radius];
%                 xyLines_y_vals = -xyLength/2:singleDimensions(1).getLengthInM():xyLength/2;
%                 xyLines_z = [locationInM(3) - (zLength/2), locationInM(3) + (zLength/2)];
%                 
%                 aboutZ = [0,0,1]; % need this axis to rotate around
%                 [theta, ~] = cart2pol(locationInM(1), locationInM(2));
%                 rotAngle = theta * Constants.rad_to_deg;
%                 
%                 for i=1:length(xyLines_y_vals)
%                     xyLines_y = xyLines_y_vals(i);
%                     
%                     % plot top z line
%                     x = xyLines_x;
%                     y = [xyLines_y, xyLines_y];
%                     z = xyLines_z;
%                     
%                     topLineHandle = line(x, y, z, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
%                     
%                     % plot bottom xy line
%                     x = [radius + detectorLineHeight, radius + detectorLineHeight];
%                     y = [xyLines_y, xyLines_y];
%                     z = xyLines_z;
%                     
%                     botLineHandle = line(x, y, z, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
%                     
%                     % rotate so that middle is at start point
%                     rotate(topLineHandle, aboutZ, rotAngle);
%                     rotate(botLineHandle, aboutZ, rotAngle);
%                 end
%                 
%                 % *****************************************************
%                 % plot perpendicular to xy lines, aka connect top and
%                 % bottom detector lines that we just plotted
%                 
%                 perpLines_x = [radius, radius + detectorLineHeight];
%                 perpLines_y_vals = -xyLength/2:singleDimensions(1).getLengthInM():xyLength/2;
%                 
%                 if zLength == 0
%                     perpLines_z_vals = locationInM(3);
%                 else
%                     perpLines_z_vals = locationInM(3) - (zLength/2):singleDimensions(2).getLengthInM():locationInM(3) + (zLength/2);
%                 end
%                 
%                 aboutZ = [0,0,1]; % need this axis to rotate around
%                 [theta, ~] = cart2pol(locationInM(1), locationInM(2));
%                 rotAngle = theta * Constants.rad_to_deg;
%                 
%                 for i=1:length(perpLines_y_vals)
%                     for j=1:length(perpLines_z_vals)
%                         perpLines_y = perpLines_y_vals(i);
%                         perpLines_z = perpLines_z_vals(j);
%                         
%                         % plot perp line
%                         x = perpLines_x;
%                         y = [perpLines_y, perpLines_y];
%                         z = [perpLines_z, perpLines_z];
%                         
%                         lineHandle = line(x, y, z, 'Parent', axesHandle, 'Color', Constants.Detector_Colour);
%                         
%                         % rotate
%                         rotate(lineHandle, aboutZ, rotAngle);
%                     end
%                 end
            end
            
            
            if detector.movesWithSource
                % draw circle outlining the movement of the
                % detector
                
                xyRadius = norm([locationInM(1), locationInM(2)]);
                
                if zIsAngular
                    zAngle = singleDimensions(2).getAngleInDegrees() * wholeDimensions(2);
                    
                    zLength = 2 * (sind(zAngle/2) * xyRadius);
                    
                    radius = sqrt((xyRadius^2) - ((zLength/2)^2));
                else
                    zLength = singleDimensions(2).getLengthInM() * detector.wholeDetectorDimensions(2);
                    
                    radius = xyRadius;
                end
                                
                edgeColour = Constants.Detector_Colour;
                lineStyle = '--';
                lineWidth = [];
                faceColour = [];
                
                
                if zLength == 0
                    circleOrArcPatch(0, 0, locationInM(3), radius, 0, 360, edgeColour, faceColour, lineStyle, lineWidth);
                else
                    circleOrArcPatch(0, 0, locationInM(3) - (zLength/2), radius, 0, 360, edgeColour, faceColour, lineStyle, lineWidth);
                    circleOrArcPatch(0, 0, locationInM(3) + (zLength/2), radius, 0, 360, edgeColour, faceColour, lineStyle, lineWidth);
                end
                
            end
        end
        
        function handles = setGUI(detector, handles)
            x = detector.location(1);
            y = detector.location(2);
            z = detector.location(3);
            
            setDoubleForHandle(handles.detectorStartingLocationXEdit, x);
            setDoubleForHandle(handles.detectorStartingLocationYEdit, y);
            setDoubleForHandle(handles.detectorStartingLocationZEdit, z);
            
            xy = detector.wholeDetectorDimensions(1);
            z = detector.wholeDetectorDimensions(2);
            
            setDoubleForHandle(handles.detectorWholeDetectorDimensionsXYEdit, xy);
            setDoubleForHandle(handles.detectorWholeDetectorDimensionsZEdit, z);
            
            xy = detector.singleDetectorDimensions(1).value;
            z = detector.singleDetectorDimensions(2).value;
            
            xyUnits = detector.singleDetectorDimensions(1).units;
            zUnits = detector.singleDetectorDimensions(2).units;
            
            setDoubleForHandle(handles.detectorSingleDetectorDimensionsXYEdit, xy);
            setDoubleForHandle(handles.detectorSingleDetectorDimensionsZEdit, z);
            
            setSelectionForPopupMenu(handles.detectorSingleDetectorDimensionsXYUnitsPopupMenu, 'Units', xyUnits);
            setSelectionForPopupMenu(handles.detectorSingleDetectorDimensionsZUnitsPopupMenu, 'Units', zUnits);
            
            set(handles.detectorMovesWithSourceCheckbox, 'Value', detector.movesWithSource);
            
            if isempty(detector.saveFileName)
                setString(handles.detectorFileNameText, 'Not Saved');
            else
                setString(handles.detectorFileNameText, detector.saveFileName);
            end
            
            % set hidden handles
            handles.detectorSavePath = detector.savePath;
            handles.detectorSaveFileName = detector.saveFileName;
        end
        
        function detector = createFromGUI(detector, handles)
            x = getDoubleFromHandle(handles.detectorStartingLocationXEdit);
            y = getDoubleFromHandle(handles.detectorStartingLocationYEdit);
            z = getDoubleFromHandle(handles.detectorStartingLocationZEdit);
            
            detector.location = [x,y,z];
            
            xy = getDoubleFromHandle(handles.detectorWholeDetectorDimensionsXYEdit);
            z = getDoubleFromHandle(handles.detectorWholeDetectorDimensionsZEdit);
            
            detector.wholeDetectorDimensions = [xy, z];
            
            xy = getDoubleFromHandle(handles.detectorSingleDetectorDimensionsXYEdit);
            z = getDoubleFromHandle(handles.detectorSingleDetectorDimensionsZEdit);
            
            xyUnits = getSelectionFromPopupMenu(handles.detectorSingleDetectorDimensionsXYUnitsPopupMenu, 'Units');
            zUnits = getSelectionFromPopupMenu(handles.detectorSingleDetectorDimensionsZUnitsPopupMenu, 'Units');
            
            xyDimension = Dimension(xy, xyUnits);
            zDimension = Dimension(z, zUnits);
            
            detector.singleDetectorDimensions = [xyDimension, zDimension];
            
            detector.movesWithSource = get(handles.detectorMovesWithSourceCheckbox, 'Value');
            
            detector.savePath = handles.detectorSavePath;
            detector.saveFileName = handles.detectorSaveFileName;
        end
        
        function [clockwisePosZ, clockwiseNegZ, counterClockwisePosZ, counterClockwiseNegZ] = getDetectorCoords(detector, detectorPosition, xyDetector, zDetector)
            % [clockwisePosZ, clockwiseNegZ, counterClockwisePosZ, counterClockwiseNegZ] = getDetectorCoords(detector, detectorPosition, xyDetector, zDetector)
            % this gives the 4 coordinates of the detector in question with the most
            % clockwise coordinates first, and then the more counter-clockwise
            % coordinates
            
            [theta, radius] = cart2pol(detectorPosition(1), detectorPosition(2));
            theta = theta * Constants.rad_to_deg;
            
            totalNumXYDetectors = detector.wholeDetectorDimensions(1);
            totalNumZDetectors = detector.wholeDetectorDimensions(2);
            
            midXYDetector = (totalNumXYDetectors + 1) / 2;
            midZDetector = (totalNumZDetectors + 1) / 2;
            
            xyStep = (xyDetector - midXYDetector);
            zStep = (zDetector - midZDetector);
            
            clockwiseStep = xyStep + 0.5;
            counterClockwiseStep = xyStep - 0.5;
            
            positiveZStep = zStep + 0.5;
            negativeZStep = zStep - 0.5;
            
            clockwiseShift = clockwiseStep * detector.singleDetectorDimensions(1).getValueInSIUnits();
            counterClockwiseShift = counterClockwiseStep * detector.singleDetectorDimensions(1).getValueInSIUnits();
            
            positiveZShift = positiveZStep * detector.singleDetectorDimensions(2).getValueInSIUnits();
            negativeZShift = negativeZStep * detector.singleDetectorDimensions(2).getValueInSIUnits();
            
            xyIsAngular = detector.singleDetectorDimensions(1).units.isAngular;
            zIsAngular = detector.singleDetectorDimensions(2).units.isAngular;
            
            clockwisePosZ = zeros(1,3);
            clockwiseNegZ = zeros(1,3);
            counterClockwisePosZ = zeros(1,3);
            counterClockwiseNegZ = zeros(1,3);
            
            if zIsAngular
                if xyIsAngular
                    posZVal = detectorPosition(3) + radius * sind(positiveZShift);
                    negZVal = detectorPosition(3) + radius * sind(negativeZShift);
                else
                    posZVal = detectorPosition(3) + radius * sind(positiveZShift);
                    negZVal = detectorPosition(3) + radius * sind(negativeZShift);
                end
            else
                posZVal = detectorPosition(3) + positiveZShift;
                negZVal = detectorPosition(3) + negativeZShift;
            end
            
            clockwisePosZ(3) = posZVal;
            counterClockwisePosZ(3) = posZVal;
            
            clockwiseNegZ(3) = negZVal;
            counterClockwiseNegZ(3) = negZVal;
                
            
            if xyIsAngular
                clockwiseAngle = theta - clockwiseShift; %remember, minus because we do angles as positive is clockwise!
                counterClockwiseAngle = theta - counterClockwiseShift;
                    
                if zIsAngular
                    clockwiseShiftXPosZ = detectorPosition(1) + radius * cosd(clockwiseAngle) * cosd(positiveZShift);
                    clockwiseShiftYPosZ = detectorPosition(2) + radius * sind(clockwiseAngle) * cosd(positiveZShift);
                    
                    clockwiseShiftXNegZ = detectorPosition(1) + radius * cosd(clockwiseAngle) * cosd(negativeZShift);
                    clockwiseShiftYNegZ = detectorPosition(2) + radius * sind(clockwiseAngle) * cosd(positiveZShift);
                    
                    counterClockwiseShiftXPosZ = detectorPosition(1) + radius * cosd(counterClockwiseAngle) * cosd(positiveZShift);
                    counterClockwiseShiftYPosZ = detectorPosition(2) + radius * sind(counterClockwiseAngle) * cosd(positiveZShift);
                    
                    counterClockwiseShiftXNegZ = detectorPosition(1) + radius * cosd(counterClockwiseAngle) * cosd(negativeZShift);
                    counterClockwiseShiftYNegZ = detectorPosition(2) + radius * sind(counterClockwiseAngle) * cosd(negativeZShift);
                                                            
                    clockwisePosZ(1) = clockwiseShiftXPosZ;
                    clockwiseNegZ(1) = clockwiseShiftXNegZ;
                    
                    counterClockwisePosZ(1) = counterClockwiseShiftXPosZ;
                    counterClockwiseNegZ(1) = counterClockwiseShiftXNegZ;
                    
                    clockwisePosZ(2) = clockwiseShiftYPosZ;
                    clockwiseNegZ(2) = clockwiseShiftYNegZ;
                    
                    counterClockwisePosZ(2) = counterClockwiseShiftYPosZ;
                    counterClockwiseNegZ(2) = counterClockwiseShiftYNegZ;
                else                    
                    clockwiseShiftX = detectorPosition(1) + cosd(clockwiseAngle) * radius;
                    clockwiseShiftY = detectorPosition(2) + sind(clockwiseAngle) * radius;
                    
                    counterClockwiseShiftX = detectorPosition(1) + cosd(counterClockwiseAngle) * radius;
                    counterClockwiseShiftY = detectorPosition(2) + sind(clockwiseAngle) * radius;
                                        
                    clockwisePosZ(1) = clockwiseShiftX;
                    clockwiseNegZ(1) = clockwiseShiftX;
                    
                    counterClockwisePosZ(1) = counterClockwiseShiftX;
                    counterClockwiseNegZ(1) = counterClockwiseShiftX;
                    
                    clockwisePosZ(2) = clockwiseShiftY;
                    clockwiseNegZ(2) = clockwiseShiftY;
                    
                    counterClockwisePosZ(2) = counterClockwiseShiftY;
                    counterClockwiseNegZ(2) = counterClockwiseShiftY;
                end
            else
                clockwiseShiftX = detectorPosition(1) + clockwiseShift * cosd(theta + 90);
                counterClockwiseShiftX = detectorPosition(1) + counterClockwiseShift * cosd(theta + 90);
                
                clockwiseShiftY = detectorPosition(2) + clockwiseShift * sind(theta + 90);
                counterClockwiseShiftY = detectorPosition(2) + counterClockwiseShift * sind(theta + 90);
                
                clockwisePosZ(1) = clockwiseShiftX;
                clockwiseNegZ(1) = clockwiseShiftX;
                
                counterClockwisePosZ(1) = counterClockwiseShiftX;
                counterClockwiseNegZ(1) = counterClockwiseShiftX;
                
                clockwisePosZ(2) = clockwiseShiftY;
                clockwiseNegZ(2) = clockwiseShiftY;
                
                counterClockwisePosZ(2) = counterClockwiseShiftY;
                counterClockwiseNegZ(2) = counterClockwiseShiftY;
            end
                               
            
        end

    end
    
end


function detectorLineHeight = getDetectorLineHeight(detector)
singleDims = detector.singleDetectorDimensions;

len = length(singleDims);

dimensionLengths = zeros(len,1);

for i=1:len
    dim = singleDims(i);
    
    if dim.units.isAngular
        dimensionLengths(i) = dim.getLengthInM(norm(detector.location), detector.locationUnits);
    else
        dimensionLengths(i) = dim.getLengthInM();
    end
end

maxLen = max(dimensionLengths);
scaleFactor = 1;

detectorLineHeight = scaleFactor * maxLen;
end


function angle = findAngleForPerpendicularArc(theta, psi, radius)
% theta is the angle that the perpendicular arc is rotated (aka 0 is
% centre)
% psi is the max angle of the arcs that this arc will be perpendicular to
% radius is the radius of these arcs

% STEP 1: If we project a circle tilted from a plane at psi, it becomes an
% ellipse
% we'll assume that the ellipse is oriented such that the x-axis radius is
% unchanged, and y-axes is changed
% aka circle was titled about x-axis

a = radius; % x axis
b = radius*cosd(psi); % y axis

[x, y] = getEllipseXAndY(a, b, theta);

% STEP 2: If we then look down the x-axis, the titled circle will appear to
% be a straight line (of length radius) at angle psi
% we can then use the y value we just found, and use this as a horizontal
% point in this view. The height of our perpendiular arc can then be found

height = y * tand(psi);

% STEP 3: Then knowing the height and radius, the angle can easily be
% figured out
% Angle MUST be negative!

angle = -abs(asind(height / radius));

end


function  [x, y] = getEllipseXAndY(a, b, theta)

theta = theta + 90; %flip into proper axis (x unstretched, y scaled)

if mod(theta, 90) == 0 && mod(theta, 180) ~= 0
    x = 0;
else
    x = (((tand(theta)^2)/(b^2)) + (1/(a^2))) ^ -0.5;
end

y = b * sqrt(1 - ((x^2)/(a^2)));

end