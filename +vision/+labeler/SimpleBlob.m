classdef SimpleBlob < vision.labeler.AutomationAlgorithm & vision.labeler.mixin.Temporal
    
    %----------------------------------------------------------------------
    % Algorithm Description
    %----------------------------------------------------------------------

    properties(Constant)
        
        % Name: Give a name for your algorithm.
        Name = 'Simple Blob Algorithm';
        
        % Description: Provide a one-line description for your algorithm.
        Description = 'This is a simple blob detector for defining BBoxes.';
        
        % UserDirections: Provide a set of directions that are displayed
        %                 when this algorithm is invoked. The directions
        %                 are to be provided as a cell array of character
        %                 vectors, with each element of the cell array
        %                 representing a step in the list of directions.
        UserDirections = {...
            ['Automation algorithms are a way to automate manual labeling ' ...
            'tasks. This AutomationAlgorithm uses simple blob Analysis and an ' ...
            'intially created ROIs to track the selected Objects.'], ...
            ['The Algorithm is sensible against a lot of noise and incontinous frames.' ], ...
            ['ROI Selection: Draw an ROI.  In order to import previously ' ...
            'labeled ROI''s select them (click for a single ROI, ' ...
            'Ctrl+Click for multiple ROI''s) prior to Automation.'], ...
            ['Run: Press RUN to run the automation algorithm. '], ...
            ['If the Algorithm got interrupted with an error, it might result ' ...
            'from a changing number of ROIs. You need to change the value for ' ...
            'Area Thresholding in the Settings (Standard: 1000)']};
    end
    
    %----------------------------------------------------------------------
    % Settings Properties
    %----------------------------------------------------------------------
    properties
       
        % Area Threshold
        areaThreshold = 1000
        
        %Dilation Size
        dilationSize = 20
        
    end
    
    %---------------------------------------------------------------------
    % Step 2: Define properties to be used during the algorithm. These are
    % user-defined properties that can be defined to manage algorithm
    % execution.
    properties
        
        %InitialLabels Set of labels at algorithm initialization
        %   Table with columns Name, Type and Position for labels marked at
        %   initialization.
        InitialLabels
        
        %Number of BBoxes
        %   Number of BBoxes in the Initial State
        numBBoxes
        
        %BBoxPoints Bounding Box points
        %   Cell array of bounding box corner points for each tracker.
        BBoxPoints
    end
    
    %----------------------------------------------------------------------
    % Step 3: Define methods used for setting up the algorithm.
    methods
        function flag = supportsReverseAutomation(~)
            flag = true;
        end  
        
        function isValid = checkLabelDefinition(~, labelDef)
            
            % Only Rectangular ROI label definitions are valid for the
            % Point Tracker.
            isValid = labelDef.Type==labelType.Rectangle;
        end
              
        function isReady = checkSetup(~, videoLabels)
            
            % There must be at least one ROI label before the algorithm can
            % be executed.
            assert(~isempty(videoLabels), 'There are no ROI labels to track. Draw at least one ROI label.');
            
            isReady = true;   
        end
        
        % c) Optionally, specify what settings the algorithm requires by
        %    implementing the settingsDialog method. This method is invoked
        %    when the user clicks the Settings button. If your algorithm
        %    requires no settings, remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.settingsDialog
        %
        function settingsDialog(algObj)
            
            disp('Executing settingsDialog')
            prompt = {'set value for area threshold from 100 - 10000'};
            dlgTitle = 'Area Threshold';
            dims = [1 50];
            defInput = {num2str(algObj.areaThreshold)};
            algObj.areaThreshold = str2double(inputdlg(prompt,dlgTitle, dims, defInput));
            
            prompt = {'set value for dilation size from 2 - 50'};
            dlgTitle = 'Dilation Size';
            dims = [1 50];
            defInput = {num2str(algObj.dilationSize)};
            algObj.dilationSize = str2double(inputdlg(prompt,dlgTitle, dims, defInput));
            
            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
            
            
        end
    end
    
    %----------------------------------------------------------------------
    % Step 4: Specify algorithm execution. This controls what happens when
    %         the user presses RUN. Algorithm execution proceeds by first
    %         executing initialize on the first frame, followed by run on
    %         every frame, and terminate on the last frame.
    methods
        % a) Specify the initialize method to initialize the state of your
        %    algorithm. If your algorithm requires no initialization,
        %    remove this method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.initialize
        %
        function initialize(algObj, ~, labelsToAutomate)
            
            % Cache initial labels marked during setup. These will be used
            % as initializations for point trackers.
            algObj.InitialLabels = labelsToAutomate;
            
            algObj.numBBoxes = height(labelsToAutomate);
          
            algObj.BBoxPoints = zeros(algObj.numBBoxes, 4);      
            
        end
        
        % b) Specify the run method to process an image frame and execute
        %    the algorithm. Algorithm execution begins at the first image
        %    frame in the interval and is sequentially invoked till the
        %    last image frame in the interval. Algorithm execution can
        %    produce a set of labels which are to be returned in
        %    autoLabels.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.run
        %
        function autoLabels = run(algObj, I)
            autoLabels = [];
            % Check which labels were marked on this frame. These will be
            % used as initializations for the trackers.
            idx = algObj.InitialLabels.Time==algObj.CurrentTime;
            
            % Convert to HSV space
            I_hsv = rgb2hsv(I);
            
            if any(idx)
                % Initialize new trackers for each of the labels marked on
                % this frame.
                idx = find(idx);
%                 algObj.IndexList = [algObj.IndexList; idx(:)];
                
                InitializeBBoxes(algObj, idx);
                
            else
                % Find New BBoxes
                autoLabels = createNewBBoxes(algObj, I_hsv);
                algObj.BBoxPoints = reshape([autoLabels.Position], algObj.numBBoxes, 4)';
            end
            
            disp(['Executing run on image frame at ' char(seconds(algObj.CurrentTime))])
            
            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
            
            
            
        end
        
        % c) Specify the terminate method to clean up state of the executed
        %    algorithm. If your method requires no clean up, remove this
        %    method.
        %
        %    For more help,
        %    >> doc vision.labeler.AutomationAlgorithm.terminate
        %
        function terminate(algObj)
            
            disp('Executing terminate')
            
            % Empty arrays
            algObj.InitialLabels  = [];
            algObj.BBoxPoints     = {};

        end
    end
    
    %----------------------------------------------------------------------
    % Private methods
    %----------------------------------------------------------------------
    methods (Access = private)
        
        function InitializeBBoxes(algObj, idx)
            % Save BBox for later use
            algObj.BBoxPoints = algObj.InitialLabels{idx, 'Position'}; 

        end
        
        function autoLabels = createNewBBoxes(algObj, I_hsv)
            autoLabels = [];
            
            % Use Saturation layer for otsu threshholding
            thresholdValue = graythresh(I_hsv(:,:,2));
            binaryImage  = imbinarize(I_hsv(:,:,2), thresholdValue);
            
            % Dilate and Erode Image
            se_size = algObj.dilationSize;
            se = strel('rectangle',[se_size, se_size]);
            BW2 = imdilate(binaryImage, se);
            BW2 = imerode(BW2, se);
            
            labeledImage = logical(BW2);  
            
            blobMeasurements = regionprops(labeledImage, BW2, 'all');
            for k = 1 : length(blobMeasurements)
                if blobMeasurements(k).Area > algObj.areaThreshold
                    BBox = blobMeasurements(k).BoundingBox;
                    
                    % Calculate Difference between old BBoxes and new one
                    Delta = abs(algObj.BBoxPoints - BBox);
                    
                    % Find minimal difference
                    sumOfBBoxes = sum(Delta,2);
                    idx = find(sumOfBBoxes==min(sumOfBBoxes));
                    
                    newLabel = findNewBBox(algObj, idx, BBox);
                    autoLabels = [autoLabels newLabel]; %#ok<AGROW>
                    
                end
            end
        end
        
        function autoLabel = findNewBBox(algObj, idx, BBox)
            % Add a new label at newPosition
            type = algObj.InitialLabels{idx,'Type'};
            name = algObj.InitialLabels{idx,'Name'};
            autoLabel = struct('Type', type, 'Name', name, 'Position', BBox);
        end
        
    end
end