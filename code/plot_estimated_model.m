function [CellName, w_opt,probinfo,pest] = plot_estimated_model(FileName,MakePNGS)

[~,fighandles,CellName]=eval_rhabdomys_ests_neuroDA(FileName,struct('MakeFigs',1,'SaveData',0));
if MakePNGS
print_plots(fighandles,CellName)
end
load(FileName,'w_opt','probinfo');
pest=w_opt(end-length(probinfo.defaultp)+1:end);
end