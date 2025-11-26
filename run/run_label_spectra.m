%% TODO: 
% change fucntion so it handles an input array of file paths.
% this way the function need to be called only once and all the data
% handling can happen inside the function
% msa file gives in header infos about energy/channel -> is this correct? (slightly different to 10ev)
%% Plot parameters
disp('test1')
elements=["Al","Si"];
max_keV=3;
fig_size=[28,18];

transitions=["KL 2" ,"KL 3","KM 1","KM 2","L 1 M 2","L 1 M 3","L2 M 1","L 2 M 4"];
%% Plot and label the spectra

% addpath("src\")
% weird hack for correct file path in scripts
mfilePath = mfilename('fullpath');
if contains(mfilePath,'LiveEditorEvaluationHelper')
    mfilePath = fileparts(matlab.desktop.editor.getActiveFilename);
end

src_dir = fullfile(run_dir, '..', 'src');
addpath(src_dir);

% chose spectra to plot
[files, folder] = uigetfile( ...
    {'*.csv;*.msa', 'Spectra (*.csv, *.msa)'}, ...
    'Select spectra', ...
    'MultiSelect', 'on');

% Normalize output
if ischar(files)
    files = {files};
end

abs_paths = fullfile(folder, files);   % cell array of absolute paths

edx_label_infos = read_NIST_peak_information(elements);
elements_transitions_id = ismember(edx_label_infos.Transition, transitions);

% get peak positions of selected transitions from database
elements_transitions = edx_label_infos(elements_transitions_id, :);

figure; 
% label and plot spectra. returns a fig handle for further figure
% manipulation

plt_label=false;
for i = 1:numel(abs_paths)
    spectrum_path = abs_paths{i};
    if i==length(abs_paths)
        plt_label=true; % this way only last plot contributes the labels
    end

    fig_handle = label_spectra(spectrum_path, elements_transitions, max_keV, plt_label, fig_size);
    [~, name, ext] = fileparts(abs_paths{i});
    file_names{i} = [name, ext];
end

legend(file_names)
%% Export the figure
% either export with internal matlab tool or altmany export_fig (recommended for journals)
% saving as pdf/vector formats requires ghostscript: https://ghostscript.com/releases/gsdnld.html

% path to altmany export
addpath('P:\projects\projects by number\179xx\17995_Dissertation Zrim\Coding\Matlab\altmany-export_fig-3.46.0.0')

exports_dir = fullfile(run_dir, '..', 'exports');


file_name="tmp_fig.pdf";
export_path=fullfile(exports_dir,file_name);
% set size of figure: -> figure size defined in main function, this ensures
% correct label positions.

% set(gcf,'Units','centimeters','Position',[0 0 8 6]); % width=8 cm, height=6 cm

% % % % Recommended export 
set(gca,'LooseInset',get(gca,'TightInset')); % remove extra white margins
export_fig(export_path,'-pdf','-painters','-transparent','-nocrop');
% % % % 

%  save either with matlab saveas 
% saveas(gcf, 'spectrum-saveas.png');

% or with export fig altmany function: saves fig as it apperas on screen
% export_fig spectrum-altmanytest.png -m2


% export_fig('spectrum-altmany2.pdf','-pdf','-painters','-r600','-transparent');


% export_fig options: 
% -pdf, -eps, -png, -tiff → output format
% -r300, -r600 → resolution for raster (dpi)
% -painters, -opengl → renderer (vector vs. raster)
% -transparent → transparent background
% -nocrop → keep original figure margins
