function returnvalue=label_spectra(spectrum_path,elements,max_kev)
    
    [~, ~, file_type] = fileparts(spectrum_path);
    file_type = erase(file_type, '.');  % remove the dot


    switch file_type
       case "csv"
          spectrum_data = readtable(spectrum_path);
          spectrum_data.Var1=spectrum_data.Var1/100; % convert channels into keV
          spectrum_data = renamevars(spectrum_data, 'Var1', 'energy');
          spectrum_data = renamevars(spectrum_data, 'Var2', 'counts');
       case "msa"
          spectrum_data=read_emsa(spectrum_path);
        
       otherwise
          
    end

    

    % id of max_keV
    idx = spectrum_data.energy < max_kev;
    
    hold on;

    plot(spectrum_data.energy(idx), spectrum_data.counts(idx));

    % Plot spectrum
    xlabel('Energy (KeV)');
    ylabel('Counts');
 
    % Read and filter NIST peak data - now handled in fun_func
    % edx_label_infos = read_NIST_peak_information();
    % element_peaks = [];
    % 
    % for i = 1:length(elements)
    %     matches = edx_label_infos(strcmp(edx_label_infos.Element, elements{i}), :);
    %     element_peaks = [element_peaks; matches]; 
    % end
    % 
    % element_peaks.Experimental_eV=element_peaks.Experimental_eV/1000; % convert to keV

    %%%%%%%%%%%%%%%%% first iteration of label plots 
    % Plot vertical lines and labels for each peak
    % for i = 1:height(element_peaks)
    %     x = element_peaks.Experimental_eV(i)/1000;
    %     y = max(spectrum_data.Var2(idx)) * 0.9; % place labels near top of plot
    %     xline(x, 'r--');
    %     text(x, y, append(element_peaks.Element{i},element_peaks.Transition{i}), 'Rotation', 90, ...
    %         'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontSize', 8);
    % end
    %%%%%%%%%%%%%%%%%

    % Prepare offsets to avoid overlapping boxes
    plottedY = []; % stores y positions of already plotted boxes
    % minBoxSpacing = 0.05 * max(spectrum_data.Var2(idx)); % minimum vertical spacing
    minBoxSpacing=0.1;
    
    % Filter data by idx 
    xFiltered = spectrum_data.energy(idx);
    yFiltered = spectrum_data.counts(idx);

    for i = 1:height(elements)
        xPeak = elements.Experimental_eV(i);

        % Find local max Y around the peak for placing box
        xRange = 0.01; % eV window around peak
        xMask = xFiltered >= xPeak - xRange & xFiltered <= xPeak + xRange;
        if any(xMask)
            yPeak = max(yFiltered(xMask)); % only use filtered y values
        else
            yPeak = max(yFiltered);
        end

        % Add vertical offset to avoid overlapping boxes
        yBox = yPeak * 1.05; % start slightly above peak
        while any(abs(yBox - plottedY) < minBoxSpacing)
            yBox = yBox + minBoxSpacing; % increase offset if too close
        end
        plottedY = [plottedY, yBox];

        % Plot dashed line from box to x-axis
        line([xPeak xPeak], [0 yBox], 'LineStyle', '--', 'Color', 'r');

        % Plot box with text
        strLabel = append(elements.Element{i},": ", elements.Transition{i});

        % Convert to normalized figure coordinates for annotation,
        % necessary as annotation() needs figure coordinates
        %%%% text with anotation 
        % ax = gca;
        % xNorm = (xPeak - ax.XLim(1)) / (ax.XLim(2) - ax.XLim(1));
        % yNorm = (yBox - ax.YLim(1)) / (ax.YLim(2) - ax.YLim(1));
        % annotation('textbox', [xNorm, yNorm, 0.05, 0.03], 'String', strLabel, ...
        %     'EdgeColor', 'k', 'BackgroundColor', 'w', 'HorizontalAlignment', 'center', ...
        %     'VerticalAlignment', 'bottom', 'FontSize', 8);
        %%%%
        % Draw text box with label
        
        text(xPeak, yBox, strLabel, 'EdgeColor', 'k', 'BackgroundColor', 'w', ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

    end


    
end