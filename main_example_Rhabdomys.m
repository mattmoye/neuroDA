%% Example main script for performing DA on the Rhabdomys dataset
performDA=0;
%% Make data for estimation 
modeltouse=6.5; % model identifier, outlined in the function
SHOWFIGS=1; % show some figures reflecting how the data is being used
dsf=5; % down sample factor
make_rhabdomys_neuroDA_details(modeltouse,SHOWFIGS,dsf)

%% Perform DA
if performDA
SEEDNUM=1; % iterate over this (preferably parallelize) for multi-start
DATACASE=2;
Rhabdomys_strongDA(SEEDNUM,DATACASE,[pwd,'\EstimatedModels\Cell10_0003_190620'])
end
%


FileName='Est35Seed16u1Strong_SimpsonHermite_dt0pt08_ObsFNCell10_0003_190620_Pulses_SeriesData1_DSF_5_NumObs7DSF1_mumps_T2020_3_17.mat';
MakePNGS=1;
plot_estimated_model(FileName,MakePNGS)