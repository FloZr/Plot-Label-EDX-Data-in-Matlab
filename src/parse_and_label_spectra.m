% TODO: offset if labels are close together- maybe stacked? - add option to
% add a line at the label position for K-L edges
% convert to GUI ?

function GnuPlotHandle=parseAndPlotGnuplot(filePath,PlotTitle,DrawLines)
    % Read the Gnuplot file
    if ~isfile(filePath)
        error('The file "%s" does not exist.', filePath);
    end
    fileContent = fileread(filePath);

    % Extract all data blocks marked by "plot '-'"
    dataBlocks = extractDataBlocks(fileContent);

    % Parse ranges, labels, and annotations
    xrange = parseRange(fileContent, 'set xrange');
    yrange = parseRange(fileContent, 'set yrange');
    xlabelText = parseLabel(fileContent, 'set xlabel');
    % ylabelText = parseLabel(fileContent, 'set ylabel');
    ylabelText="Counts";
    annotations = parseAnnotations(fileContent);

    % Create the plot
    GnuPlotHandle=figure;
    hold on;
    
    % extract the spectra names 
    % legendNames=string(extractLegendNames(fileContent));
    legendNames=cellfun(@string, extractLegendNames(fileContent), 'UniformOutput', false);  % Use num2str for each cell element
    % Plot each spectrum in dataBlocks
    for i = 1:length(dataBlocks)
        block = dataBlocks{i};
        if isempty(block)
            continue; % Skip empty blocks
        end
        % if i == 1
        plot(block(1,:), block(2, :), 'LineWidth', 1.5, 'DisplayName', legendNames{i});
      
        % else
            % stem(block(1, :), block(2, :), 'DisplayName', sprintf('Impulse %d', i));
        % end
    end
    hold on 
    % Apply axis labels and ranges
    if ~isempty(xrange), xlim(xrange); end
    if ~isempty(yrange), ylim(yrange); end
    xlabel(xlabelText, 'FontSize', 14);
    ylabel(ylabelText, 'FontSize', 14);
    

    
    % Initialize an array to store positions of previously placed labels
    labelPositions = [];
    
    for i = 1:size(annotations, 1)
        % Filter out empty cells and extract the numeric data
        % Find the maximum value of all spectra at the label position and
        % plots it above that spectrum + the offset
        OffSet = 1000;
        data = findMaxInRangeMulti(dataBlocks, annotations{i, 2}(1) - 10, annotations{i, 2}(1) + 10);
        nonEmptyData = cellfun(@(x) ~isempty(x), data); % Logical array where 1 means the cell is not empty
        nonEmptyValues = cellfun(@(x) x, data(nonEmptyData), 'UniformOutput', false); % Extract non-empty values
        
        % Flatten the nested cell arrays to a numeric array
        flattenedData = cell2mat(nonEmptyValues);
        
        maxValue = max(flattenedData);
        maxValue = maxValue + OffSet;
    
        % Avoid overlapping labels
        xPos = annotations{i, 2}(1);
        yPos = maxValue;
        
        if i==1
            labelPositions = [labelPositions; xPos, yPos];
        end
        
                % check if labels are too low in the figure with normalized axis
        % coordinates, set minimum at yMin
        AX=axis(gca); %can use this to get all the current axes
        Xrange=AX(2)-AX(1);
        Yrange=AX(4)-AX(3);


        
        yMin=0.1*Yrange;

        if yPos<yMin
            yPos=yMin;
        end

        % Adjust yPos if it overlaps with any existing label
        % while any(abs(yPos - labelPositions(:, 2)) < 200 & abs(xPos - labelPositions(:, 1)) < 200) % Adjust the tolerance (20) as needed
        %     yPos = yPos + 200; % Increment the y position to avoid overlap
        % end
        
        % checks for normalize y coordinate overlap

        if i~=1
            while any(abs(xPos - labelPositions(:, 1)) < 100 & abs(yPos - labelPositions(:, 2))<Yrange*0.025)
                yPos = yPos + 200; % Increment the y position to avoid overlap
            end
        end


        % Add the label and store its position
        hText=text(xPos, yPos, annotations{i, 1}, ...
            'HorizontalAlignment', 'center', 'FontSize', 12);
        if DrawLines
            line([xPos, xPos], [0, yPos-Yrange*0.01], 'Color', 'r', 'LineWidth', 1,'HandleVisibility','off','LineStyle','--'); % Red vertical line
        end
        % add new label
        if i~=1
            labelPositions = [labelPositions; xPos, yPos];
        end
        
        %    % Get the text extent for the current label
        % textExtent = get(hText, 'Extent'); % [x, y, width, height]
        % 
        % % Draw a rectangle around the text
        % rectangle('Position', [textExtent(1), textExtent(2), textExtent(3), textExtent(4)], ...
        %     'EdgeColor', 'blue', 'LineWidth', 1.5); % Customize the box style
    end


    % Finalize
    title(PlotTitle, 'FontSize', 16);
    grid on;
    legend('show', 'Interpreter', 'none');
    hold off;
end


function dataBlocks = extractDataBlocks(content)
    % Extract data blocks that are between "plot" (or any other block start)
    % and the character "e", which marks the end of each data block
    blockExpr = '([^\n]*\n)([\s\S]*?)\ne'; % Capture any block ending with "e"
    matches = regexp(content, blockExpr, 'tokens'); % Extract each block as a token
    
    dataBlocks = cell(size(matches));
    for i = 1:length(matches)-1
        block = matches{i}{2};  % Extract the data portion (skip any preamble)        
        block = regexprep(block, '\s+', ' ');            % Replace multiple spaces with a single space
        block = regexp(block, '.*[a-zA-Z](.*)', 'tokens', 'once');
        block = strtrim(block);                         % Remove leading/trailing spaces
       
        % Convert cleaned block into numeric data
        try

             % Parse as space-separated or comma-separated values
            lines = splitlines(block); % Split into individual lines
            lines=strrep(lines,',','');
            split_data = strsplit(lines{1});
            x=str2double(split_data(1:2:end));
            y=str2double(split_data(2:2:end));
            dataBlocks{i} = [x ;y];
        catch
            warning('Failed to parse data block %d.', i);
            dataBlocks{i} = [];
        end
    end
end



function range = parseRange(content, keyword)
    % Extract range for set xrange or set yrange
    expr = sprintf('%s \\[(.*?)\\]', keyword);
    match = regexp(content, expr, 'tokens', 'once');
    if ~isempty(match)
        range = str2double(strsplit(match{1}, ':'));
    else
        range = [];
    end
end

function label = parseLabel(content, keyword)
    % Extract label for set xlabel or set ylabel
    expr = sprintf('%s "(.*?)"', keyword);
    match = regexp(content, expr, 'tokens', 'once');
    if ~isempty(match)
        label = match{1};
    else
        label = '';
    end
end

function legends = extractLegendNames(content)
    % Find the line containing the plot command and extract the title names
    % Look for the pattern 'plot "-" with lines  title "some_title"'
    
    % Define a regular expression to match the 'title "some_title"' pattern
    expr = 'title "([^"]+)"';
    
    % Find all occurrences of the pattern in the content
    matches = regexp(content, expr, 'tokens');
    
    % Extract and return the legend names as a cell array
    legends = cellfun(@(x) x{1}, matches, 'UniformOutput', false);
end


function annotations = parseAnnotations(content)
    % Step 1: Extract labels without the question mark
    labelExpr = 'set label \d+ "([^"]+)"'; % Regex to capture the label text between quotes (without ?)
    labelMatches = regexp(content, labelExpr, 'tokens'); % Extract label text
    
    % Step 2: Extract coordinates (X, Y)
    coordExpr = 'set label \d+ "([^"]+)" at first ([\d.]+),([\d.]+)'; % Regex to capture coordinates after label
    coordMatches = regexp(content, coordExpr, 'tokens'); % Extract coordinates
    
    % Ensure the number of labels matches the number of coordinates
    assert(length(labelMatches) == length(coordMatches), 'Mismatch between labels and coordinates.');
    
    % Step 3: Store the annotations (label text and coordinates)
    annotations = cell(length(labelMatches), 2); % Initialize cell array to store the annotations
    for i = 1:length(labelMatches)
        annotations{i, 1} = strrep(labelMatches{i}{1}, '?', ''); % Label text without '?'
        annotations{i, 2} = [str2double(coordMatches{i}{2}), str2double(coordMatches{i}{3})]; % Coordinates (X, Y)
    end
    
    % Step 4: Identify duplicates and keep only the first occurrence
    [uniqueLabels, ~, labelIndices] = unique(annotations(:, 1)); % Find unique labels and their indices
    labelCounts = histc(labelIndices, 1:length(uniqueLabels)); % Count the occurrences of each label
    
    % Step 5: Remove duplicates (keep only the first occurrence)
    % Find indices of duplicate entries
    duplicateIndices = find(labelCounts > 1); % Indices of labels that appear more than once
    
    % Remove the second and subsequent occurrences of each duplicate label
    for i = 1:length(duplicateIndices)
        labelToRemove = uniqueLabels{duplicateIndices(i)};
        duplicatePositions = find(strcmp(annotations(:, 1), labelToRemove)); % Find positions of duplicates
        annotations(duplicatePositions(2:end), :) = []; % Remove all but the first occurrence
    end
end


function [maxY, closestX] = findMaxInRangeMulti(dataBlocks, xMin, xMax)
    % for plotting the elemental labels at the max count of all spectra

    % Initialize output variables
    maxY = cell(1, length(dataBlocks));  % Cell array to store max Y values for each data block
    closestX = cell(1, length(dataBlocks)); % Cell array to store corresponding X values
    
    % Loop over each data block
    for k = 1:length(dataBlocks)-1
        % Extract the x and y values from the current data block
        x = dataBlocks{k}(1, :);
        y = dataBlocks{k}(2, :);
        
        % Step 1: Find the indices of x values within the range [xMin, xMax]
        inRangeIndices = find(x >= xMin & x <= xMax); % Indices of x values within range
        
        if isempty(inRangeIndices)
            % If no x values are exactly in range, find the closest ones
            [~, minXIdxLow] = min(abs(x - xMin)); % Index for closest x to xMin
            [~, minXIdxHigh] = min(abs(x - xMax)); % Index for closest x to xMax
            
            % Get the closest x values
            closestXLow = x(minXIdxLow);
            closestXHigh = x(minXIdxHigh);
            
            % Restrict to the closest x-values and find the corresponding y-values
            if closestXLow < closestXHigh
                validIndices = find(x >= closestXLow & x <= closestXHigh);
            else
                validIndices = find(x <= closestXLow & x >= closestXHigh);
            end
            closestX{k} = x(validIndices);
            maxY{k} = max(y(validIndices)); % Find max y value in the new range
        else
            % Step 2: If there are x values within the range, find the max y-value in the range
            % Extract the corresponding y values
            xInRange = x(inRangeIndices);
            yInRange = y(inRangeIndices);
            
            % Step 3: Find the maximum y value in the range
            [maxY{k}, maxIdx] = max(yInRange);
            
            % Step 4: Store the corresponding x value for the max y value
            closestX{k} = xInRange(maxIdx);
        end
    end
end