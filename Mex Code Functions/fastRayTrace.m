function rawDetectorValue = fastRayTrace(pointSourceCoords, pointDetectorCoords, phantomLocationInM, phantomDims, voxelDimsInM, phantomData, startingIntensity)
% rawDetectorValue = fastRayTrace(pointSourceCoords, pointDetectorCoords, phantomLocationInM, phantomDims, voxelDimsInM, phantomData, startingIntensity)

bounds1 = [phantomLocationInM(1), phantomLocationInM(2:3) - voxelDimsInM(2:3).*phantomDims(2:3)];
bounds2 = [phantomLocationInM(1)+voxelDimsInM(1)*phantomDims(1), phantomLocationInM(2:3)];

[deltas, sourceStartingPoint] = createLineEquation(pointSourceCoords, pointDetectorCoords);

invDeltas = 1 ./ deltas;

tMinsTemp = (bounds1 - sourceStartingPoint) .* invDeltas;
tMaxsTemp = (bounds2 - sourceStartingPoint) .* invDeltas;

tMins = tMinsTemp;
tMaxs = tMaxsTemp;

negDeltas = deltas < 0;

tMins(negDeltas) = tMaxsTemp(negDeltas);
tMaxs(negDeltas) = tMinsTemp(negDeltas);

tMin = -Inf;
tMax = Inf;

if deltas(1) ~= 0
    if tMins(1) > tMin
        tMin = tMins(1);
    end
    if tMaxs(1) < tMax
        tMax = tMaxs(1);
    end
elseif sourceStartingPoint(1) > bounds2(1) || sourceStartingPoint(1) < bounds1(1)
    tMin = Inf;
    tMax = -Inf;
end

if deltas(2) ~= 0
    if tMins(2) > tMin
        tMin = tMins(2);
    end
    if tMaxs(2) < tMax
        tMax = tMaxs(2);
    end
elseif sourceStartingPoint(2) > bounds2(2) || sourceStartingPoint(2) < bounds1(2)
    tMin = Inf;
    tMax = -Inf;
end

if deltas(3) ~= 0
    if tMins(3) > tMin
        tMin = tMins(3);
    end
    if tMaxs(3) < tMax
        tMax = tMaxs(3);
    end
elseif sourceStartingPoint(3) > bounds2(3) || sourceStartingPoint(3) < bounds1(3)
    tMin = Inf;
    tMax = -Inf;
end

if tMax < tMin
    rawDetectorValue = startingIntensity;
else % run through the voxels
    sourceStartingPoint = sourceStartingPoint - phantomLocationInM; %shift over so corner is at origin
    
    currentT = tMin;
    currentPoint = sourceStartingPoint + currentT .* deltas;
    endingT = tMax;
        
    % have starting point and end point, now will find which voxels and with
    % what distances across each voxel the ray travels
       
    radonSum = 0;
    
    isVoxelDim0 = (voxelDimsInM == 0);
    
    isDelta0 = (deltas == 0);
    isDeltaNeg = (deltas < 0);
    invVoxelDims = 1 ./ voxelDimsInM;
    
    nextLatticeAdder = sign(deltas) .* [1 -1 -1];
    
    latticeToIndex = isDeltaNeg;
    latticeToIndex(1) = ~latticeToIndex(1);
    
    latticeToIndex(isDelta0) = 1; %needs to be, since we always floor to find the lattice for delta == 0
    
    while endingT - currentT > Constants.Round_Off_Error_Bound
        currentLattices = getLattices(currentPoint, invVoxelDims, isVoxelDim0, isDeltaNeg, isDelta0);
        
        nextLattices = currentLattices + nextLatticeAdder;
        
        tValsForNextLattices = ((nextLattices .* voxelDimsInM .* [1 -1 -1]) - sourceStartingPoint) .* invDeltas;
                
        nextT = min(tValsForNextLattices(~isDelta0));
        
        nextPoint = sourceStartingPoint + nextT .* deltas;
        
        length = norm(currentPoint - nextPoint);
        indices = currentLattices + latticeToIndex;
        
        attenuation = phantomData(indices(2), indices(1), indices(3));
                
        currentT = nextT;
        currentPoint = nextPoint;
        radonSum = radonSum + length .* attenuation;        
    end
    
    rawDetectorValue = startingIntensity.*exp(-radonSum);
end

end

% ** HELPER FUNCTIONS **

function lattices = getLattices(point, invVoxelDims, isVoxelDim0, isDeltaNeg, isDelta0)
    
    unroundedVals = point .* invVoxelDims;
    
    unroundedVals = [1 -1 -1].*unroundedVals;
            
    % first need to kill off any rounding errors
    unroundedVals = roundToLevel(unroundedVals, Constants.Round_Off_Level);
    
    % no round to get lattice/index values
    isDeltaNeg(1) = ~isDeltaNeg(1);
    selectFloor = isDeltaNeg | isDelta0; % ceiling if delta is positive ONLY
        
    floorVals = floor(unroundedVals(selectFloor));
    ceilVals = ceil(unroundedVals(~selectFloor));
     
    lattices =  zeros(1,3);
    
    lattices(selectFloor) = floorVals;
    lattices(~selectFloor) = ceilVals;
    lattices(isVoxelDim0) = 0;
end

function roundedValues = roundToLevel(unroundedValues, level)
    roundedValues = floor((unroundedValues.*(10^level)) + 0.5).*(10^(-level));
end