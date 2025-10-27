function spectrum_data=read_emsa(spectrum_path)
    
    lines = readlines(spectrum_path);
    % Extract XPERCHAN value
    xperchanLine = lines(startsWith(lines, "#XPERCHAN"));
    xperchan = str2double(extractAfter(xperchanLine, ':'));

    % Find the line where data starts
    dataStart = find(startsWith(lines, '#SPECTRUM'), 1) + 1;

    % Read counts (Y values)
    y = str2double(erase(lines(dataStart:end), ','));
    y = y(~isnan(y));  % remove any empty lines

    % Create energy axis in keV
    x = (0:length(y)-1)' * xperchan / 1000;  % convert eV → keV
    spectrum_data.energy=x;
    spectrum_data.counts=y;

end