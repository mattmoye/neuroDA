function [] = print_plots(fighandles,CellName)

set(fighandles(1), 'Position', get(0, 'Screensize'));
print(fighandles(1),['analysisPlots\',CellName,'_Figure1','.png'],'-dpng','-r300')
set(fighandles(2), 'Position', get(0, 'Screensize'));
print(fighandles(2),['analysisPlots\',CellName,'_Figure2','.png'],'-dpng','-r300')
set(fighandles(3), 'Position', get(0, 'Screensize'));
print(fighandles(3),['analysisPlots\',CellName,'_Figure3','.png'],'-dpng','-r300')
end