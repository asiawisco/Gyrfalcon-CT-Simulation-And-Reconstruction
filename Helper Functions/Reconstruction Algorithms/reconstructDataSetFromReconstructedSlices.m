function reconDataSet = reconstructDataSetFromReconstructedSlices(reconSlices, sliceCentreLocationsInM, dataSetLocationInM, dataSetVoxelDimsInM, dataSetDims, reconSliceLocationInM, reconSliceVoxelDimsInM, reconSliceDims, interpolationType)
% reconDataSet = reconstructDataSetFromReconstructedSlices(reconSlices, sliceLocationsInM, dataSetLocationInM, dataSetVoxelDimsInM, dataSetDims, reconSliceLocationInM, reconSliceVoxelDimsInM, reconSliceDims, interpolationType)

reconDataSet = zeros(dataSetDims);

xStart = dataSetLocationInM(1);
yStart = dataSetLocationInM(2);
zStart = dataSetLocationInM(3);

delX = dataSetVoxelDimsInM(1);
delY = dataSetVoxelDimsInM(2);
delZ = dataSetVoxelDimsInM(3);

numX = dataSetDims(1);
numY = dataSetDims(2);
numZ = dataSetDims(3);

% these are the coords of the centre of the reconDataSet voxels
% we will use these points as the coords to interpolate to from the given
% recon slices
xVoxelPoints = (xStart + delX / 2):delX:(xStart + (delX * numX) - (delX / 2));
yVoxelPoints = (yStart - (delY * numY) - (delY / 2)):delY:(yStart - delY / 2);
zVoxelPoints = (zStart + delZ / 2):delZ:(zStart + (delZ * numZ) - (delZ / 2));

[xDataSetPoint, yDataSetPoint, zDataSetPoint] = meshgrid(xVoxelPoints, yVoxelPoints, zVoxelPoints);

% know need coords for the slice data

sliceXStart = reconSliceLocationInM(1);
sliceYStart = reconSliceLocationInM(2);

sliceDelX = reconSliceVoxelDimsInM(1);
sliceDelY = reconSliceVoxelDimsInM(2);

sliceNumX = reconSliceDims(1);
sliceNumY = reconSliceDims(2);

xSlicePoints = (sliceXStart + sliceDelX / 2):sliceDelX:(sliceXStart + (sliceDelX * sliceNumX) - (sliceDelX / 2));
ySlicePoints = (sliceYStart + (sliceDelY * sliceNumY) - (sliceDelY / 2)):sliceDelY:(sliceYStart + sliceDelY / 2);

% slice locations give the centre of the recon'ed slice
% most slices are 2D (aka no z height, and so they're only at that centre
% slice value)
% But...for the sake of completeness, if we had think slices (aka like in
% helical scanners) or cone beam imaging, we want to be apply to combine
% multiple slices, and so this would give the shifts, so that from the
% centre z coord, the z coords of all the voxels in the thick slice could
% be found

sliceDelZ = reconSliceVoxelDimsInM(3); %should be 0 for 2D slices
sliceNumZ = reconSliceDims(3); % should be 1 for 2D slices

delZDiv2 = sliceDelZ / 2;

endPoint = (sliceNumZ / 2)*sliceDelZ - delZDiv2;

zSliceShiftsFromCentre = -endPoint:delZ:endPoint;

% compile all the slice data and accompanying z vals

numSlices = length(reconSlices);

zSlicePoints = zeros(1, numSlices * sliceNumZ);
sliceData = zeros(sliceNumX, sliceNumY, numSlices * sliceNumZ);

if numSlices < 1
    reconDataSet = NaN .* ones(dataSetDims); % no recon possible
else
    for i=1:numSlices
        reconSliceData = reconSlices{i};
        
        zVals = sliceCentreLocationsInM(i) + zSliceShiftsFromCentre;
        
        zSlicePoints((i-1)*sliceNumZ + 1 : i*sliceNumZ) = zVals;
        sliceData(:,:,(i-1)*sliceNumZ + 1 : i*sliceNumZ) = reconSliceData;
    end
    
    % some "thick" slices may overlap, so we need to sort this!
    [sortedZVals, sortedI] = sort(zVals);
    
    sortedSliceData = sliceData(:,:,sortedI);
    
    % if any z-val is represented multiply times, we should fix that
    prevVal = NaN;
    numDuplicates = 1;
    sliceSum = zeros(sliceNumX, sliceNumY); % we'll average the slice values here!    
    
    endVal = length(sortedZVals);
    
    i = 1;
    
    while i <= endVal
        curVal = sortedZVals(i);
        
        if prevVal == curVal
            numDuplicates = numDuplicates + 1;
            sliceSum = sliceSum + sortedSliceData(:,:,i);
            
            % clear out the duplicated values
            sortedZVals(i) = [];
            sortedSliceData(:,:,i) = []; % don't worry, we've got the sum of slices to average stored!
            
            endVal = endVal - 1; %the length of the z vals just became 1 shorter
            
            % no need to increment i, since we just cleared out the values
            % at i
        elseif prevVal ~= curVal && numDuplicates > 0
            sortedSliceData(:,:,i-1) = sliceSum ./ numDuplicates; %take the average
            numDuplicates = 1; %reset
            
            % continue checking along
            prevVal = curVal;
            sliceSum = sortedSliceData(:,:,i);
            i = i + 1;
        else % no duplicates, just checking along            
            prevVal = curVal;
            sliceSum = sortedSliceData(:,:,i);
            i = i + 1;
        end
        
    end
    
    [knownX, knownY, knownZ] = meshgrid(xSlicePoints, ySlicePoints, sortedZVals);
    
    knownVals = sortedSliceData;
    
    valForPointsBeyondRange = NaN;
    
    reconDataSet = interp3(...
        knownX, knownY, knownZ, knownVals,...
        xDataSetPoint, yDataSetPoint, zDataSetPoint,...
        interpolationType, valForPointsBeyondRange);
end


end
