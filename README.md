# Plot EDX Data

Plots EDX Data from either msa or csv files.
Execute run_label_spectra with the elements+transitions that should be plotted. 
Peak positions are read in with read_NIST_peak_information, which is parsed from the NIST X-ray Transition Energies Database (https://physics.nist.gov/PhysRefData/XrayTrans/Html/search.html)
The spectra are then plotted and labeled with label_spectra.
