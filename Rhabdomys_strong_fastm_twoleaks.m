function [] = Rhabdomys_strong_fastm_twoleaks(SeedNum,CASE,varargin)
%% Rhabdomys SCN run script
% Written by Matthew Moye

if nargin > 2
    saveDir=varargin{1};
else
    saveDir='';
end
ModelLoaded=0;
RunWithoutControl=0;
RampUpControl=0;
switch CASE
    case 2
        modelDataFileName='Cell10_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case2.mat';
    case 2.1
        modelDataFileName='Cell10_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case2pt1.mat';
    case 2.2
        modelDataFileName='Cell10_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case2pt2.mat';
    case 1
        modelDataFileName='Cell10_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case1.mat';
    case 1.2
        modelDataFileName='Cell10_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case1pt2.mat';
    case 1.5
        modelDataFileName='Cell10_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case1pt5.mat';
    case 1.6
       modelDataFileName= 'Cell10_0003_190706_Pulsesdata_SCN_new_Ia_tauall_case1pt6.mat';
        ModelLoaded=1;
    case 3
        modelDataFileName='Cell14_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case3.mat';
    case 4
        modelDataFileName='Cell6_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case4.mat';
    case 5
        modelDataFileName='Cell7_0005_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case5.mat';
    case 6
        modelDataFileName='Cell13_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case6.mat';
    case 7
        modelDataFileName='Cell14_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case7.mat';
    case 8
        modelDataFileName='Cell19_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case8.mat';
    case 9
        modelDataFileName='Cell21_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case9.mat';
    case 10
        modelDataFileName='Cell5_0003_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case10.mat';
    case 11
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case11.mat';
      case 11.1
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_case11pt1.mat';
        ModelLoaded=1;
    case 11.2
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_v1_case11pt2.mat';
        ModelLoaded=1;
    case 11.31
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v1_case11pt3.mat';
        ModelLoaded=1;
    case 11.32
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v2_case11pt3.mat';
        ModelLoaded=1;
    case 11.41
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v1_case11pt4.mat';
        ModelLoaded=1;
    case 11.42
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v2_case11pt4.mat';
        ModelLoaded=1;
            case 11.50
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case11pt5.mat';
        ModelLoaded=1;
      %  RunWithoutControl=1;
        RampUpControl=1;

         case 11.51
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v1_case11pt5.mat';
        ModelLoaded=1;   
      %  RunWithoutControl=1;
        RampUpControl=1;

    case 11.52
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v2_case11pt5.mat';
        ModelLoaded=1;
       % RunWithoutControl=1;
        RampUpControl=1;

    case 11.60
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case11pt6.mat';
        ModelLoaded=1;
%RunWithoutControl=1;
RampUpControl=1;
    case 11.62
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_v2_case11pt6.mat';
        ModelLoaded=1;
%RunWithoutControl=1;
RampUpControl=1;
    case 11.70
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case11pt7.mat';
        ModelLoaded=1;
        RampUpControl=0;
    case 11.71
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_case11pt7.mat';
        ModelLoaded=1;
        RampUpControl=0;
    case 11.72
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIhInap_tauall_case11pt7.mat';
           ModelLoaded=1;
        RampUpControl=0;
    case 11.73
                modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ih_tauall_case11pt7.mat';
           ModelLoaded=1;
        RampUpControl=0;
            case 11.77
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_case11pt77.mat';
        ModelLoaded=1;
                    case 11.80
                modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case11pt8.mat';
        ModelLoaded=1;
        RampUpControl=0;   
            case 11.81
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_case11pt8.mat';
        ModelLoaded=1;
        RampUpControl=0;
            case 11.82
         modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_oneleak_case11pt8.mat';
        ModelLoaded=1;
        RampUpControl=0;
    case 11.83
                modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ih_tauall_case11pt8.mat';
        ModelLoaded=1;
        RampUpControl=0;
    case 11.84
        modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_Ia_tauall_case11pt8.mat';
        ModelLoaded=1;
    case 11.9
                modelDataFileName='Cell16_0004_190620_Pulsesdata_SCN_new_IaIh_tauall_case11pt9.mat';
        ModelLoaded=1;
        RampUpControl=0;    

    case 12
        modelDataFileName='Cell14_0005_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case12.mat';
    case 13
        modelDataFileName='Cell15_0003_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case13.mat';
    case 14
        modelDataFileName='Cell_14_0003_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case14.mat';
    case 15
        modelDataFileName='Cell_15_0003_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case15.mat';
    case 15.2
        modelDataFileName='Cell_15_0003_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case15pt2.mat';
        ModelLoaded=1;
            case 15.3
        modelDataFileName='Cell_15_0003_191126_Pulsesdata_SCN_new_Ia_tauall_case15pt3.mat';
        ModelLoaded=1;
    case 16
        modelDataFileName='Cell12_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case16.mat';
    case 17
        modelDataFileName='Cell6_0004_190617_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case17.mat';
    case 18
        modelDataFileName='Cell8_0003_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case18.mat';
            case 18.2
        modelDataFileName='Cell8_0003_190709_Pulsesdata_SCN_new_Ia_tauall_case18pt2.mat';
        ModelLoaded=1;
    case 19
        modelDataFileName='Cell9_0003_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case19.mat';
    case 20
        modelDataFileName='Cell4_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case20.mat';
    case 21
        modelDataFileName='Cell_14_0003_191215_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case21.mat';
    case 21.2
        modelDataFileName='Cell_14_0003_191215_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case21pt2.mat';
        ModelLoaded=1;
    case 21.25
             modelDataFileName='Cell_14_0003_191215_Pulsesdata_SCN_new_Ia_tauall_case21pt2.mat';
        ModelLoaded=1;
    case 22
        modelDataFileName='Cell_17_0003_191215_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case22.mat';
    case 23
        modelDataFileName='Cell_1_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case23.mat';
    case 24
        modelDataFileName= 'Cell_4_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case24.mat';
    case 25
        modelDataFileName= 'Cell7_0003_191220_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case25.mat';
    case 26
        modelDataFileName= 'Cell_18_0003_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case26.mat';
    case 27
        modelDataFileName= 'Cell17_0003_191220_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case27.mat';
    case 28
        modelDataFileName= 'Cell14_0005_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case28.mat';
    case 29
        modelDataFileName= 'Cell15_0003_190709_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case29';
    case 30
        modelDataFileName='Cell_17_0003_191215_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case30.mat';
    case 31
        modelDataFileName='Cell8_0003_190706_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case31.mat';
         case 31.8
        modelDataFileName='Cell8_0003_190706_Pulsesdata_SCN_new_IaIh_tauall_case31pt8.mat';
                ModelLoaded=1;
    case 31.89
        modelDataFileName='Cell8_0003_190706_Pulsesdata_SCN_new_Ia_tauall_case31pt8.mat';
        ModelLoaded=1;
    case 32
        modelDataFileName='Cell_4_0003_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case32.mat';
    case 33
        modelDataFileName='Cell1_0004_190617_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case33.mat';
    case 34
        modelDataFileName='Cell_13_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case34.mat';
    case 35
        modelDataFileName='Cell_16_0003_191215_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case35.mat';
    case 36
        modelDataFileName='Cell_14_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case36.mat';
    case 37
        modelDataFileName='Cell7_0004_190617_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case37.mat';
    case 38
        modelDataFileName='Cell9_0003_190620_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case38.mat';
    case 39
        modelDataFileName='Cell_3_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case39.mat';
    case 40
        modelDataFileName='Cell_3_0004_191126_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case40.mat';
    case 41
        modelDataFileName='Cell19_0003_190709_Pulsesdata_SCN_new_IaIh_tauall_case41.mat';
        ModelLoaded=1;
    case 41.9
        modelDataFileName='Cell19_0003_190709_Pulsesdata_SCN_new_Ia_tauall_case41.mat';
        ModelLoaded=1;
    case 42
        modelDataFileName='Cell_16_0003_191124_Pulsesdata_SCN_new_mtau_fastm_twoleaks_case42.mat';
        ModelLoaded=1;
    case 43
        modelDataFileName='Cell17_0003_190706_Pulsesdata_SCN_new_Ia_tauall_case43.mat';
        ModelLoaded=1;
end


if ~contains(modelDataFileName,'twoleaks')
    ODEmodel=@casadi_Belle2009_new_mtau_fastm;
else
    ODEmodel=@casadi_Belle2009_new_mtau_fastm_twoleaks;
end
if ModelLoaded
    load(modelDataFileName,'ODEmodel');
end
%% Import and downsample the data
%
%%
% change linear_solver value: 'ma_57' to 'mumps' if ma57 not installed.
run_Run_ODE_4dvar_multiple_collocation(SeedNum,'UseModelData',modelDataFileName,ODEmodel,  ...
    'UseControl',1,'SmoothControl',0,'ControlPenalty',1,'ControlBound',1.0','yinds',1,'TOL',1e-12,...
    'METHODTOUSE','Strong','varannealbounds',[75,75],'hessian_approximation','exact',...
    'ControlAtEnd',0,'linear_solver','mumps','SaveLagGrad',0,'UseSlack',0,'UseAdaptive',1,...
    'correctLJPData',0,'alpha0',1.5,'UseColpack',1,'ScaleSlack',1,'ScaleConstraints',1,...
    'saveDir',saveDir,'PenalizeSlope',0,'RunWithoutControl',RunWithoutControl,...
    'RampUpControl',RampUpControl)

