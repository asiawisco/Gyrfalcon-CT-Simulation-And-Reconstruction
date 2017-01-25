function intersectionPoints = findLinePhantomIntersections(lineDeltas, linePoint, startPoint, phantomLocation,  phantomVoxelDims, phantomData)
%linePhantomIntersectionPoints = findLinePhantomIntersections(lineDeltas, linePoint, startPoint, phantomLocation,  phantomVoxelDims, phantomData)
    
phantomDims = size(phantomData);

phantX = phantomLocation(1);
phantY = phantomLocation(2);
phantZ = phantomLocation(3);
    
phantDelX = phantomVoxelDims(1);
phantDelY = phantomVoxelDims(2);
phantDelZ = phantomVoxelDims(3);

phantNumX = phantomDims(2); %Yup these should be reversed, remember MATLAB does (rows, cols, slice) for size(), so (y,x,z)
phantNumY = phantomDims(1);
phantNumZ = phantomDims(3);

linePhantomIntersectionPoints = [];
linePhantomIntersectionPointNorms = []; 

counter = 1;

bounds = [...
    phantX, phantX + phantNumX*phantDelX;
    phantY - phantNumY*phantDelY, phantY;
    phantZ - phantNumZ*phantDelZ, phantZ];

% NOTE: phantomLocation

% Get YZ Plane Intersections

for i=0:phantNumX
    xVal = phantX + i*phantDelX;
    
    interceptPoint = interceptPointOfLineWithPlaneWithinBounds(linePoint, lineDeltas, xVal, 1, bounds);
    
    if ~isempty(interceptPoint)
        linePhantomIntersectionPoints(counter,:) = interceptPoint;
        linePhantomIntersectionPointNorms(counter,:) = norm(interceptPoint - startPoint); % we keep track of the norm so that we can order these intercepts from hit first to hit last later
        
        counter = counter + 1;
    end
end

% Get XZ Plane Intersections

for i=0:phantNumY
    yVal = phantY - i*phantDelY;
    
    interceptPoint = interceptPointOfLineWithPlaneWithinBounds(linePoint, lineDeltas, yVal, 2, bounds);
    
    if ~isempty(interceptPoint)
        linePhantomIntersectionPoints(counter,:) = interceptPoint;
        linePhantomIntersectionPointNorms(counter,:) = norm(interceptPoint - startPoint); % we keep track of the norm so that we can order these intercepts from hit first to hit last later
        
        counter = counter + 1;
    end
end

% Get XY Plane Intersections

for i=0:phantNumZ
    zVal = phantZ - i*phantDelZ;
    
    interceptPoint = interceptPointOfLineWithPlaneWithinBounds(linePoint, lineDeltas, zVal, 3, bounds);
    
    if ~isempty(interceptPoint)
        linePhantomIntersectionPoints(counter,:) = interceptPoint;
        linePhantomIntersectionPointNorms(counter,:) = norm(interceptPoint - startPoint); % we keep track of the norm so that we can order these intercepts from hit first to hit last later
        
        counter = counter + 1;
    end
end

if ~isempty(linePhantomIntersectionPoints)
    % pre processing to get rid of "different values", but whose norms are
    % within a nanometer
    
    roundOff = 10^8; % within 1nm
    
    roundingNorms = linePhantomIntersectionPointNorms * roundOff;
    
    roundedLinePhantomIntersectionPointNorms = round(roundingNorms) / roundOff;
    
    % now sort and eliminate doubles/triples (if intersection occured at
    % lattice point in voxel grid)
    
    [~,sortedIndices,~] = unique(roundedLinePhantomIntersectionPointNorms);
    
    intersectionPoints = linePhantomIntersectionPoints(sortedIndices,:);
else
    intersectionPoints = [];
end

end
