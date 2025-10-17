%%
disp("hasdf")

%%
% Robustly add project 'src' folder to path (works when run from run/plot_spectra.m)
thisFile = mfilename('fullpath');
if isempty(thisFile)
    % likely running as a script; try to get current editor filename (desktop only)
    try
        editorFile = matlab.desktop.editor.getActiveFilename;
        scriptDir = fileparts(editorFile);1+1
    catch
        scriptDir = pwd; % fallback
    end
else
    scriptDir = fileparts(thisFile);
end

% scriptDir is expected to be the run/ folder; project root is parent
projectRoot = fileparts(scriptDir);
srcDir = fullfile(projectRoot, 'src');

if exist(srcDir, 'dir')
    addpath(srcDir);            % add only src
    % addpath(genpath(srcDir)); % uncomment to add src and all its subfolders
else
    warning('Could not find src folder at: %s', srcDir);
end

title="l-family";
FileName='crossalloy';

lines=1; % 1 if lines to x axis should be drawn
FigureHandle=parseAndPlotGnuplot(FileName,title,lines);


%% save figures
addpath('P:\projects\projects by number\179xx\17995_Dissertation Zrim\Coding\Matlab\altmany-export_fig-3.46.0.0')

%  save either with matlab saveas 
saveas(gcf, 'test.png');

% or with export fig altmany function: saves fig as it apperas on screen
export_fig test2.png -m2
