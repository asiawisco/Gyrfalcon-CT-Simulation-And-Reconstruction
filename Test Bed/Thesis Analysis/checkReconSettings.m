function [] = checkReconSettings()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

savePath = 'E:\Thesis Results\Recon Settings Check.xls';

sheetName = 'OSC-TV_RR n Opt.';

root = 'E:\Local Gyrfalcon Data\Imaging Scan Runs\Optical CT Imaging Scan Run (';

gels = {...
    'Gel 4-2', 151:164;...
    'Gel 4-2 FF-D', 151:164;...
    'Gel 4-2 FF-R', 151:164};

% gels = {...
%     'Gel 2-2', 1:2;...    
%     'Gel 2-2 FF-D', 1:2;...
%     'Gel 2-2 FF-R', 1:2;...
%     'Gel 2-4', 51:52;...    
%     'Gel 2-4 FF-D', 51:52;...
%     'Gel 2-4 FF-R', 51:52;...
%     'Gel 4-2', [57,157,164,171];...    
%     'Gel 4-2 FF-D', [57,157,164,171];...
%     'Gel 4-2 FF-R', [57,157,164,171];...
%     'Gel 4-4', 1:2;...    
%     'Gel 4-4 FF-D', 1:2;...
%     'Gel 4-4 FF-R', 1:2;...
%     'Gel 5-2', 1:2;...    
%     'Gel 5-2 FF-D', 1:2;...
%     'Gel 5-2 FF-R', 1:2;...
%     'Gel 5-3', 1:2;...    
%     'Gel 5-3 FF-D', 1:2;...
%     'Gel 5-3 FF-R', 1:2;...
%     'Gel 5-4', 1:2;...    
%     'Gel 5-4 FF-D', 1:2;...
%     'Gel 5-4 FF-R', 1:2;...
%     'Gel 6-2a', 1:2;...    
%     'Gel 6-2a FF-D', 1:2;...
%     'Gel 6-2a FF-R', 1:2;...
%     'Gel 6-2b', 1:2;...    
%     'Gel 6-2b FF-D', 1:2;...
%     'Gel 6-2b FF-R', 1:2;...
%     'Gel 6-3b', 1:2;...    
%     'Gel 6-3b FF-D', 1:2;...
%     'Gel 6-3b FF-R', 1:2;...
%     'Gel 7-2a', 1:2;...    
%     'Gel 7-2a FF-D', 1:2;...
%     'Gel 7-2a FF-R', 1:2;...
%     'Gel 7-2b', 1:2;...    
%     'Gel 7-2b FF-D', 1:2;...
%     'Gel 7-2b FF-R', 1:2;...
%     'Gel 7-3', 1:2;...    
%     'Gel 7-3 FF-D', 1:2;...
%     'Gel 7-3 FF-R', 1:2};

results = {...
    'Gel Name', 'Recon #', 'RR', 'n', 's', 'c', 'Recon Volume 1', 'Recon Volume 2', 'Recon Volume 3', 'Detector'};

for i=1:length(gels)
    disp(i);
    
    gelName = gels{i,1};
    reconNums = gels{i,2};
    
    for j=1:length(reconNums)
        reconNum = reconNums(j);
        
        loadPath = [root, gelName, ')\Thesis Recon ', num2str(reconNum), ' (CBCT OSC-TV)\Thesis Recon ', num2str(reconNum), ' (CBCT OSC-TV).mat'];
        
        data = load(loadPath);
        
        run = data.run;
        recon = run.reconstruction;
        
        n = recon.numberOfIterations;
        s1 = recon.initialBlockSize;
        s2 = recon.finalBlockSize;
        c = recon.c;
        
        dims1 = size(recon.reconDataSetSlices{1});
        dims2 = recon.reconSliceDimensions;
        dims3 = recon.reconDataSetDimensions;
        
        rayRejection = recon.useRayRejection;
        
        detectorSize = recon.processingWholeDetectorDimensions;
        
        newRow = {...
            gelName, reconNum, rayRejection, n, ['[',num2str(s1),'..',num2str(s2),']'],...
            c, [num2str(dims1(1)), ' x ', num2str(dims1(2)), ' x ', num2str(dims1(3))],...
            [num2str(dims2(1)), ' x ', num2str(dims2(2)), ' x ', num2str(dims2(3))],...
            [num2str(dims3(1)), ' x ', num2str(dims3(2)), ' x ', num2str(dims3(3))],...
            [num2str(detectorSize(1)), ' x ', num2str(detectorSize(2))]};
        
        results = [results; newRow];
    end
end

xlswrite(savePath, results, sheetName);

end

