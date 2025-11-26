function fig_handle=label_spectra(spectrum_path,elements,max_kev,plot_labels,fig_size)

% LABEL_SPECTRA  Plot and label an EDX spectrum.
%
%   fig_handle = label_spectra(spectrum_path, elements_transitions, ...
%                              max_kev, plot_labels, fig_size)
%
%   Plots the EDX spectrum stored at *spectrum_path* (CSV or MSA) and
%   labels the peaks/transitions specified in *elements_transitions* up to
%   *max_kev*. 
%
%   *plot_labels*   – set true to display peak labels.
%   *fig_size*      – 1×2 vector [width_cm, height_cm] defining the figure
%                      size in centimeters.
%
%   The function returns the handle of the generated figure.


    [~, ~, file_type] = fileparts(spectrum_path);
    file_type = erase(file_type, '.');  % removes the dot


    switch file_type
       case "csv"
          spectrum_data = readtable(spectrum_path);
          spectrum_data.Var1=spectrum_data.Var1/100; % convert channels into keV
          spectrum_data = renamevars(spectrum_data, 'Var1', 'energy');
          spectrum_data = renamevars(spectrum_data, 'Var2', 'counts');
       case "msa"
          spectrum_data=read_emsa(spectrum_path);
        otherwise
            error('Unsupported file type');
          
    end

    % id of max_keV
    idx = spectrum_data.energy < max_kev;
    
    hold on;


    fig = gcf;
    fig.Units = 'centimeters';
    fig.Position(3) = fig_size(1); % width in cm
    fig.Position(4) = fig_size(2);  % height in cm 

    % this ensures plot is centered on screen. 
    % cirumvents weird matlab bug where figure will be outside the
    % screen range
    screensize_px = get(0,'ScreenSize');  % [left bottom width height in px]
    dpi = get(0,'ScreenPixelsPerInch');             % pixels per inch
    px_to_cm = 2.54 / dpi;                           % conversion factor
    screen_width_cm  = screensize_px(3) * px_to_cm;
    screen_height_cm = screensize_px(4) * px_to_cm;

    % compute centered position
    fig_x = (screen_width_cm  - fig_size(1)) / 2;
    fig_y = (screen_height_cm - fig_size(2)) / 2;

    % set position
    fig.Position(1) = fig_x;
    fig.Position(2) = fig_y;

    ax = gca;
    ax.Units = 'centimeters';
 
    % Plot spectrum
    spectrum_energy=spectrum_data.energy;
    
    % insert 0 so plot starts at 0
    spectrum_energy=[0; spectrum_energy];
    spectrum_energy=spectrum_energy(1:end-1);
    
    % this represents channels the best
    stairs(spectrum_energy(idx), spectrum_data.counts(idx),'LineWidth',2.5)
    
    % visual formatting of figure
    ax = gca;
    ax.LineWidth = 1.2;
    ax.FontSize = 11;          % tick labels
    ax.FontName = 'Arial';

    xlabel('Energy (keV)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Counts',        'FontSize', 12, 'FontWeight', 'bold');
    ax.GridAlpha = 0.15;
    grid on;

    if ~plot_labels
        fig_handle = gcf;
        return;
    end

    % Filter data by idx 
    xFiltered = spectrum_data.energy(idx);
    yFiltered = spectrum_data.counts(idx);

    % Prepare offsets to avoid overlapping boxes
    plottedY = []; % stores y positions of already plotted boxes
    plottedX=[];

    ax = gca;

    % minimum distances of text boxes
    minBoxSpacingFactor = 0.05; 
    minBoxSpacing = minBoxSpacingFactor * diff(ax.YLim); % fraction of Y-axis range
    minBoxSpacingX = 0.02 * diff(ax.XLim); % fraction of X-axis range
   
    % loop over each peak
    for i = 1:height(elements)
        xPeak = elements.Experimental_eV(i);

        % Find local max Y around the peak for placing box
        xRange = 0.01; % keV window around peak
        xMask = xFiltered >= xPeak - xRange & xFiltered <= xPeak + xRange;

        if any(xMask)
            yPeak = max(yFiltered(xMask)); % only use filtered y values
        else
            yPeak = max(yFiltered);
        end

        yBox = yPeak +minBoxSpacing*0.75; % start label slightly above peak

        % if y distance between text boxes is smaller than minBoxSpacing increase the y
        % spacing, while also checking if they would overlap in x
        
        while any(abs(yBox - plottedY) < minBoxSpacing*1.3) && any(abs(xPeak - plottedX) < minBoxSpacingX*1.3)
            yBox = yBox + minBoxSpacing*0.25; % increase offset if too close
        end


        plottedY(end+1) = yBox;
        plottedX(end+1) = xPeak;

        % Plot dashed line from box to x-axis
        line([xPeak xPeak], [0 yBox], 'LineStyle', '--','LineWidth',1.5);
   
         % Plot box with text
        strLabel = append(elements.Element{i},": ", elements.Transition{i});

        text(xPeak, yBox, strLabel, 'EdgeColor', 'k', 'BackgroundColor', 'w', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9);

    end

    %%%%%% this finds all the text labels , excluding ticks and axis
    %%%%%% labels, and brings them in front of the spectrum. maybe put this
    %%%%%% in extra function that gets called in run_func, then the order
    %%%%%% of calling the fcuntions wouldnt matter
    ax = gca;
    hTxt = findall(ax,'Type','text');

    % Exclude xlabel, ylabel, zlabel, title
    hExclude = [ax.XLabel, ax.YLabel, ax.ZLabel, ax.Title];
    hTxt = setdiff(hTxt, hExclude);

    for k = 1:numel(hTxt)
        uistack(hTxt(k),'top');
    end
    %%%%%%
    
    set(gca, 'LooseInset', max(get(gca,'TightInset'), 0.5))  
    hold off
    fig_handle = gcf;   % return handle of the current figure
end