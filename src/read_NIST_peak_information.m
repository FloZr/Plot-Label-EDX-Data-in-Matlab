% NIST X-Ray Transition Energies Database from https://www.nist.gov/pml/x-ray-transition-energies-database
% reads in the nist database and filters for transitions that were
% experimentally measured.
function EDX_Database=read_NIST_peak_information(elements)
    
    data = readtable('nist_xray_transitions.csv');
    
    % Filter rows where Experimental_eV ~= 1 and not NaN
    edx_label_infos = data(data.Experimental_eV ~= 1 & ~isnan(data.Experimental_eV), :);

    
    element_peaks = [];

    for i = 1:length(elements)
        matches = edx_label_infos(strcmp(edx_label_infos.Element, elements{i}), :);
        element_peaks = [element_peaks; matches];
    end

    element_peaks.Experimental_eV=element_peaks.Experimental_eV/1000; % convert to keV
    EDX_Database=element_peaks;
end