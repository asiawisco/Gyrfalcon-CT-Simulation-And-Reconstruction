%% Write projection data files


data = load('E:\Local Gyrfalcon Data\Imaging Scan Runs\Optical CT Imaging Scan Run (Gel 2-4)\Slice 1\Angle 0\Position (1,1) Detector Data.mat');

pre1500 = data.detectorData_I0(35:35+700-1, 163:163+700-1);
post1500 = data.detectorData_I(35:35+700-1, 163:163+700-1);

data = load('E:\Local Gyrfalcon Data\Imaging Scan Runs\Optical CT Imaging Scan Run (Gel 4-2)\Slice 1\Angle 0\Position (1,1) Detector Data.mat');

pre2000 = data.detectorData_I0(35:35+700-1, 163:163+700-1);
post2000 = data.detectorData_I(35:35+700-1, 163:163+700-1);

% analysis params
slice = 1;

rawDataThreshold = [0, 2^16];
lnDataThreshold = []; %auto

rawDataTicks = [0, 2^15, 2^16];
lnDataTicks = [];

rawDataColourbarLabel = 'Detector Value $[unitless]$';
lnDataColourbarLabel = '$ln(I_0/I) $ $[unitless]$';

profile1_X = [325 374];
profile1_Y = [350 350];

imageHeightInCm = 3.4;

unitConversion = 1; % non-needed

lineColours = {...
    [1 0 0],...
    [0 0 1]};

lineStyles = {...
    '-',...
    '-'};

lineWidths = {1, 1};

legendLabels = {...
    'Pre',...
    'Post'};

lnLegendLabels = {...
    '16 Gy',...
    '12 Gy'};

voxelDimInMM = 1;

noShift = [0 0];

lineProfilePlotDimsInCm = [5,5];
lineProfileXAxis = 'Pixel Position $[unitless]$';
lineProfileYAxis = 'Detector Value $[unitless]$';

%% Images

root = 'E:\Thesis Figures\Results\FDK_FF\Projection Data Analysis\';

writeSliceImagesFromFigure(...
    [root, 'Gel 1500 Pre.png'],...
    pre1500,...
    unitConversion, rawDataThreshold,...
    imageHeightInCm, rawDataTicks, rawDataColourbarLabel,...
    {profile1_X}, {profile1_Y}, {[1 0 0]}, {'-'}, {2});

writeSliceImagesFromFigure(...
    [root, 'Gel 1500 Post.png'],...
    post1500,...
    unitConversion, rawDataThreshold,...
    imageHeightInCm, rawDataTicks, rawDataColourbarLabel,...
    {profile1_X}, {profile1_Y}, {[1 0 0]}, {'-'}, {2});

writeSliceImagesFromFigure(...
    [root, 'Gel 1500 Ln.png'],...
    log(pre1500./post1500),...
    unitConversion, lnDataThreshold,...
    imageHeightInCm, lnDataTicks, lnDataColourbarLabel,...
    {}, {}, {}, {}, {});

writeSliceImagesFromFigure(...
    [root, 'Gel 2000 Pre.png'],...
    pre2000,...
    unitConversion, rawDataThreshold,...
    imageHeightInCm, rawDataTicks, rawDataColourbarLabel,...
    {profile1_X}, {profile1_Y}, {[1 0 0]}, {'-'}, {2});

writeSliceImagesFromFigure(...
    [root, 'Gel 2000 Post.png'],...
    post2000,...
    unitConversion, rawDataThreshold,...
    imageHeightInCm, rawDataTicks, rawDataColourbarLabel,...
    {profile1_X}, {profile1_Y}, {[1 0 0]}, {'-'}, {2});

writeSliceImagesFromFigure(...
    [root, 'Gel 2000 Ln.png'],...
    log(pre2000./post2000),...
    unitConversion, lnDataThreshold,...
    imageHeightInCm, lnDataTicks, lnDataColourbarLabel,...
    {profile1_X}, {profile1_Y}, {[1 0 0]}, {'-'}, {2});

%% Write profiles

yLims = [0, 2^16 / 2 + 4000];

takeAndPlotLineProfiles(...
    [root, 'Gel 1500 Profiles.png'],...
    {pre1500, post1500},...
    {[6,0], [6,0]},...
    unitConversion, slice,...
    profile1_X, profile1_Y, voxelDimInMM,...
    lineProfilePlotDimsInCm, yLims,...
    lineProfileXAxis, lineProfileYAxis,...
    lineStyles, lineColours, lineWidths, legendLabels);

yLims = [0, 2^16 / 2];

takeAndPlotLineProfiles(...
    [root, 'Gel 2000 Profiles.png'],...
    {pre2000, post2000},...
    {noShift, noShift},...
    unitConversion, slice,...
    profile1_X, profile1_Y, voxelDimInMM,...
    lineProfilePlotDimsInCm, yLims,...
    lineProfileXAxis, lineProfileYAxis,...
    lineStyles, lineColours, lineWidths, legendLabels);

yLims = [0.2, 1.2];
lineProfileYAxis = '$ln(I_0/I) $ $[unitless]$';

lineColours = {...
    [0 0 0],...
    [0 0 0]};

lineStyles = {...
    '-',...
    ':'};

takeAndPlotLineProfiles(...
    [root, '1500MU vs 2000MU Ln Profiles.png'],...
    {log(pre2000./post2000), log(pre1500./post1500)},...
    {noShift, [6,0]},...
    unitConversion, slice,...
    profile1_X, profile1_Y, voxelDimInMM,...
    lineProfilePlotDimsInCm, yLims,...
    lineProfileXAxis, lineProfileYAxis,...
    lineStyles, lineColours, lineWidths, lnLegendLabels);