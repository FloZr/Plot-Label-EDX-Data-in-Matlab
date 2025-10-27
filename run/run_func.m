file_name="BDZA 11 6KV spot 2.msa";
abs_path = which(file_name);


elements=["Al","Si"];
max_keV=7;

edx_label_infos = read_NIST_peak_information(elements);

transitions="KL 2";

elements_transitions_id=edx_label_infos.Transition==transitions;

elements_transitions = edx_label_infos(elements_transitions_id, :);

label_spectra(abs_path,elements_transitions,max_keV)