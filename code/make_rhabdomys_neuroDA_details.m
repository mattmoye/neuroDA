function [] = make_rhabdomys_neuroDA_details(modeltouse,SHOWFIGS,dsf)
%% Rhabdomys SCN run script
% Written by Matthew Moye

   % modeltouse=6.5; %default 6.5, this is what ultimately impacts the final section of the code
   % SHOWFIGS=1; % plot any intermediate figures
    IappStepVec=-30:5:30; % reflects applied current range for dataset
    StepOne=2.6641e4; % when the change occurs.
    StepTwo=5.1641e4;
    % "dropbox" is contained in the code folder, it should be able to access the
    % root directory. might need to run "dropbox.m" in command window on first
    % use.
    saveDir=[pwd, '\', 'dataForEstimation'];
  %  dsf=5;
    dateinfo='_';
                dsfAll=0;
    CASE = 2; 
% other settings were removed for release given length of file. 
    switch CASE
        case 2
            filename=[pwd '\rawData\rhabdomys\Hyper-Depo-Pulses\190620_Pulses\matFiles\Cell10_0003.mat'];
            [a,filenameshort,c]=fileparts(filename);
            dateinfo='_190620_Pulses';
            mDFN_prefix=[filenameshort,dateinfo];
            CapEst=14.2;
            VSeriesStepOneinds=[1 6 10 13];
            VSeriesStepTwoinds=[1 5];
            timeWindow=[800 1300];
            timeWindow2=[2000 2500];         
            timeWindowSpontaneous=[500 2000];
    end
    
    mDFN_prefix = strrep(mDFN_prefix,' ','_');
    
    % Would recommend collapsing the next 3 sections when not making
    % changes to them. 
    %% Initial parameters (aren't used as ICs, set bounds to parameter to fix in estimation)
    %%% HIGHLY RECOMMEND COLLAPSINGS
    UseReduced=0;
    
    % Paramdetails
    SlopeMin=.5e1;
    TauMin=1e-2;
    %TauMax=1e1;
    TauMaxSmall=1e1;
    TauMax=4e1;
    %TauMaxMax=3e2;
    TauMaxMax=1e2;
    TauMaxMaxMax1=4e2;
    TauMaxMaxMax2=3e2;
    SlopeMax=.5e2;
    HalfActMax=0;
    HalfActMin=-70;
    HalfActMinm_na=-50;
    HalfActMinm_ca=-40;
    % Original Parameters
    p = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        0 % tm0
        -286 % vmt
        160 % dvmt;
        -62 % vh
        -4*2 %dvh
        .51 % th0
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % vn0
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    
    % Reparameterize
    
    p_new = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        0 % tm0
        0 % tm1
        -286 % vmt
        160 % dvmt;
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    
    p_new_mtau = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        0 % tm0
        0 % tm1
        -286 % vmt
        160 % dvmt;
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        3.1 %tm1_ca
        -25 %vmt_ca
        15 % dvm_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    p_new_mtau_fastm = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        3.1 %tm1_ca
        -25 %vmt_ca
        15 % dvm_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    
    p_new_mtau_fastm_twoleaks = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Glna
        1/11 % Glk
        -35.2 % vm
        8.1*2  % dvmt
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        3.1 %tm1_ca
        -25 %vmt_ca
        15 % dvm_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    
    p_new_reduced = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        0 % tm0
        0 % tm1
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        ];
    
    p_new_fastm = [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        -62 % vh
        -4*2 %dvh
        .51 % th0
        0 % th1
        -26.6 % vht
        7.1 % dvht
        14 % vn
        17*2 %dvn
        0 % tn0
        0 % tn1
        67 %vnt
        68 % dvnt
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        0 % th1_ca
        444 % vht_ca
        220 %dvht_ca
        ];
    
    p_new_taus_constant= [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        1 % taum
        -62 % vh
        -4*2 %dvh
        .51 % th0
        14 % vn
        17*2 %dvn
        0 % tn0
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        ];
    
    p_new_fastm_taus_constant= [
        5.7 % C, pF
        45 % Ena
        -97 % Ek
        54 % Eca 54-73
        -7 %- El
        229 % Gna, nS
        16% Gk, ns 13-21
        65 % Gca 53-85
        1/11 % Gl
        -35.2 % vm
        8.1*2  % dvmt
        -62 % vh
        -4*2 %dvh
        .51 % th0
        14 % vn
        17*2 %dvn
        0 % tn0
        -25 % vm_ca
        7.5*2 % dvm_ca
        3.1 %tm0_ca
        -260 % vh_ca
        -65*2 % dvh_ca
        0 % th0_ca
        ];
    %pbounds_new=[p(1:9) p(1:9)
    % pbounds_new=[p(1:5) p(1:5)
    
    %%  Bound parameters
    %%% HIGHLY RECOMMEND COLLAPSING
    pbounds_new=[
        CapEst*.9 CapEst*(1.1) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 90 % Eca 54-73
        -120 -5 %- El
        .1 300
        .1 100
        .01 100
        .01 5
        HalfActMin, HalfActMax % m
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        -40, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        ];
    
    pbounds_new_reduced=[p(1:9) p(1:9)
        HalfActMin, HalfActMax % m
        SlopeMin, SlopeMax
        TauMin, TauMax/10
        TauMin, TauMax/10
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax/10
        TauMin, TauMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMax/10
        TauMin, TauMax/10
        HalfActMin, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        ];
    
    
    pbounds_new_fastm=[
        CapEst*.9 CapEst*(1.1) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 90 % Eca 54-73
        -50 -5 %- El
        .1 300
        .1 100
        .01 100
        .01 5
        HalfActMin, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        -40, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        ];
    
    pbounds_new_m_tau=[
        CapEst*.9 CapEst*(1.1) %5.7 % C, pF
        40 60 % Ena
        -100 -80 % Ek
        54 100 % Eca 54-73
        -80 20 % El
        .1 500
        .1 100
        .01 100
        .0001 5
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMaxSmall
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        ];
    
    pbounds_new_m_tau_fastm=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -80 20 % El -29 plus minus 12 jackson et al 2004 (bruce bean paper)
        .1 500
        .1 300
        .01 300
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, 10*TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        TauMin, TauMaxMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        ];
    
    %     pbounds_new_m_tau_fastm_twoleaks=[
    %         CapEst*.8 CapEst*(1.2) %5.7 % C, pF
    %         40 50 % Ena
    %         -100 -80 % Ek
    %         54 130 % Eca 54-73
    %         .1 500
    %         .1 300
    %         .01 300
    %         .0001 10
    %         .0001 10
    %         HalfActMinm_na, HalfActMax % m
    %         SlopeMin, SlopeMax
    %         HalfActMin, HalfActMax % h
    %         -SlopeMax, -SlopeMin
    %         TauMin, TauMax
    %         TauMin, 10*TauMax% TauMin, 10*TauMax
    %         HalfActMin, HalfActMax
    %         SlopeMin, SlopeMax
    %         HalfActMin, HalfActMax % n
    %         SlopeMin, SlopeMax
    %         TauMin, TauMaxSmall
    %         TauMin, TauMax
    %         HalfActMin, HalfActMax
    %         SlopeMin, SlopeMax
    %         HalfActMinm_ca, HalfActMax % m_ca
    %         SlopeMin, SlopeMax
    %         TauMin, TauMax
    %         TauMin, 10*TauMax%TauMin, 10*TauMax
    %         HalfActMin, HalfActMax
    %         SlopeMin, SlopeMax
    %         HalfActMin, HalfActMax % h_ca
    %         -SlopeMax, -SlopeMin
    %         TauMin, TauMaxMax
    %         TauMin, TauMaxMax
    %         HalfActMin, HalfActMax
    %         SlopeMin, SlopeMax
    %         ];
    %
    pbounds_new_m_tau_fastm_twoleaks=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        .1 500
        .1 300
        .01 300
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax% TauMin, 10*TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMaxMaxMax1%or TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMaxMax2 % or Taumin, TauMax
        TauMin, TauMaxMaxMax2% or Taumin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        ];
    
    pbounds_new_m_tau_fastm_twoleaks_IaIhv1=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -40 -25 % Eh
        .1 500
        .1 300
        .01 300
        0 100 % gh
        0 100 % gto
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, 10*TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        TauMin, TauMaxMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        -90, -80 % Ih,  deJeu1997
        12, 20
        7, 70 % tau, fig 3D, dejeu1997 (scale by 10 in eqns)
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        1 100 % mult by 10 in equations
        ];
    
    pbounds_new_taus_constant=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -80 20 % El -29 plus minus 12 jackson et al 2004 (bruce bean paper)
        .1 500
        .1 300
        .01 300
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        ];
    
    pbounds_new_fastm_taus_constant=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -80 20 % El -29 plus minus 12 jackson et al 2004 (bruce bean paper)
        .1 500
        .1 300
        .01 300
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, 10*TauMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, 10*TauMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, 10*TauMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        ];
    
    
    pbounds_new_m_tau_fastm_twoleaks_Iav1=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        .1 500
        .1 300
        .01 300
        0 100 % gto
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMaxSmall
        TauMin, TauMaxSmall
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        TauMin, TauMaxMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        1 50 % mult by 10 in equations
        ];
    
    pbounds_new_m_tau_fastm_twoleaks_Iav2=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        .1 500
        .1 300
        .01 300
        0 100 % gto
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMaxSmall
        TauMin, TauMaxSmall
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMaxMax
        TauMin, TauMaxMax
        HalfActMin, HalfActMax
        SlopeMin, SlopeMax
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        TauMin, 10
        -75 -55
        -25 -10
        1 50 % mult by 10 in equations
        ];
    
    
    pbounds_new_twoleaks_IaIh_tauall=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -40 -25 % Eh
        .1 500
        .1 300
        .01 300
        0 300 % gh
        0 300 % gto
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax/2
        TauMin, TauMax
        SlopeMin, SlopeMax
        -90, -80 % Ih,  deJeu1997
        -30, -8%12, 20
        7 30
        7, 70 % tau, fig 3D, dejeu1997 (scale by 10 in eqns)
        8, 30
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        .1 10
        1 100 % mult by 10 in equations
        10 25
        ];
    
    
     pbounds_new_twoleaks_Ia_tauall=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        .1 500
        .1 300
        .01 300
        0 300 % gto
        .0001 2
        .0001 2
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax/2
        TauMin, TauMax
        SlopeMin, SlopeMax
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        .1 10
        1 100 % mult by 10 in equations
        10 25
        ];
    
    pbounds_new_twoleaks_Ih_tauall=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -40 -25 % Eh
        .1 500
        .1 300
        .01 300
        0 300 % gh
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        -90, -80 % Ih,  deJeu1997
        -30, -8%12, 20
        1 70
        7, 70 % tau, fig 3D, dejeu1997 (scale by 10 in eqns)
        8, 30
        ];
    pbounds_new_twoleaks_IaIhInap_tauall=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 130 % Eca 54-73
        -40 -25 % Eh
        .1 500
        .1 300
        .01 300
        0 300 % gh
        0 300 % gto
        0 300 % gnap
        .0001 10
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, 10*TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        -90, -80 % Ih,  deJeu1997
        -30, -8%12, 20
        1 70
        7, 70 % tau, fig 3D, dejeu1997 (scale by 10 in eqns)
        8, 30
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        .1 100
        1 100 % mult by 10 in equations
        10 25
        -40, -20 % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        ];
    
    pbounds_new_IaIh_tauall=[
        CapEst*.8 CapEst*(1.2) %5.7 % C, pF
        40 50 % Ena
        -100 -80 % Ek
        54 73 % Eca 54-73
        -60 0 % El 
        -40 -25 % Eh
        .1 500
        .1 300
        .01 300
        0 300 % gh
        0 300 % gto
        .0001 10
        HalfActMinm_na, HalfActMax % m
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % n
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMinm_ca, HalfActMax % m_ca
        SlopeMin, SlopeMax
        TauMin, TauMaxSmall
        TauMin, TauMax
        SlopeMin, SlopeMax
        HalfActMin, HalfActMax % h_ca
        -SlopeMax, -SlopeMin
        TauMin, TauMax
        TauMin, TauMax
        SlopeMin, SlopeMax
        -90, -80 % Ih,  deJeu1997
        -30, -8%12, 20
        7 30
        7, 70 % tau, fig 3D, dejeu1997 (scale by 10 in eqns)
        8, 30
        -35 -15   % Ia, bouskila and dudek 1995
        10 25
        -75 -55
        -25 -10
        .1 10
        1 100 % mult by 10 in equations
        10 25
        ];
    % passive parameters
    %passivebounds = repmat([1,50,-77,-54.4]',1,3);
    PDATA_new = [pbounds_new p_new];
    PDATA_new_reduced=[pbounds_new_reduced p_new_reduced];
    PDATA_new_fastm=[pbounds_new_fastm p_new_fastm];
    %PDATA_new_fastm_twoleak=[pbounds_new_fastm_twoleak p_new_fastm_twoleak];
    PDATA_new_mtau=[pbounds_new_m_tau p_new_mtau];
    PDATA_new_mtau_fastm=[pbounds_new_m_tau_fastm p_new_mtau_fastm];
    PDATA_new_mtau_fastm_twoleaks=[pbounds_new_m_tau_fastm_twoleaks p_new_mtau_fastm_twoleaks];
    PDATA_new_IaIh_v1=[pbounds_new_m_tau_fastm_twoleaks_IaIhv1 pbounds_new_m_tau_fastm_twoleaks_IaIhv1(:,1)];
    PDATA_new_Ia_v1=[pbounds_new_m_tau_fastm_twoleaks_Iav1 pbounds_new_m_tau_fastm_twoleaks_Iav1(:,1)];
    PDATA_new_Ia_v2=[pbounds_new_m_tau_fastm_twoleaks_Iav2 pbounds_new_m_tau_fastm_twoleaks_Iav2(:,1)];
    
        PDATA_new_IaIh_tauall = [ pbounds_new_IaIh_tauall pbounds_new_IaIh_tauall(:,1)];

    PDATA_new_twoleaks_IaIh_tauall = [pbounds_new_twoleaks_IaIh_tauall pbounds_new_twoleaks_IaIh_tauall(:,1)];
    PDATA_new_twoleaks_Ia_tauall= [pbounds_new_twoleaks_Ia_tauall pbounds_new_twoleaks_Ia_tauall(:,1)];
    PDATA_new_twoleaks_IaIhInap_tauall = [pbounds_new_twoleaks_IaIhInap_tauall pbounds_new_twoleaks_IaIhInap_tauall(:,1)];
    PDATA_new_twoleaks_Ih_tauall= [pbounds_new_twoleaks_Ih_tauall pbounds_new_twoleaks_Ih_tauall(:,1)];
    PDATA_new_taus_constant =[ pbounds_new_taus_constant p_new_taus_constant];
    PDATA_new_fastm_taus_constant =[ pbounds_new_fastm_taus_constant p_new_fastm_taus_constant];
    
    % passive parameters
    
    Nstate=6;
    compartments=1;
    nleaks=1;
    
    %% Import and downsample the data
    %%% HIGHLY RECOMMEND COLLAPSING
    clear Iappdata;
    clear Vdata;
    clear tdata;
    clear vseriesCollection;
    totalpts=0;
    filenameExt=filename(end-2:end);
    % dsf=5; % downsample factor
    if strcmp(filenameExt,'mat')
        tempstruct= load(filename); % contains Vdata, tdata, Iappdata (output from amplifier)
        if isfield(tempstruct,'Vdata')
            Vdata=tempstruct.Vdata;
        elseif isfield(tempstruct,'ObsData');
            Vdata=tempstruct.ObsData;
        else
            error('Wrong data file was passed, voltage not located');
        end
        tdata=tempstruct.tdata;
        clear tempstruct
        % Fill in Iappdata with actual values
        for i =1:size(Vdata,2)
            Iappdata(:,i)=zeros(length(tdata),1);
            Iappdata(StepOne:StepTwo-1,i)=IappStepVec(i);
        end
        % timeWindow represents our section of data to use for assimilation
        % VSeriesStepOneinds represents which protocols to use
        if ~isempty(timeWindow)
            indsWindow=find((tdata>timeWindow(1)) & tdata<timeWindow(2));
            tWindow=tdata(indsWindow);
            VWindow=Vdata(indsWindow,VSeriesStepOneinds);
            IWindow=Iappdata(indsWindow,VSeriesStepOneinds);
        end
        if ~isempty(timeWindow2)
            indsWindow2=find((tdata>timeWindow2(1)) & tdata<timeWindow2(2));
            tWindow2=tdata(indsWindow2);
            VWindow2=Vdata(indsWindow2,VSeriesStepTwoinds);
            IWindow2=Iappdata(indsWindow2,VSeriesStepTwoinds);
        end
        if exist('timeWindowAll','var')
            if ~isempty(timeWindowAll)
                indsWindowAll=find((tdata>timeWindowAll(1)) & tdata<timeWindowAll(2));
                tWindowAll=tdata(indsWindowAll);
                VWindowAll=Vdata(indsWindowAll,VSeriesStepOneStepTwoinds);
                IWindowAll=Iappdata(indsWindowAll,VSeriesStepOneStepTwoinds);
            end
        end
        if exist('timeWindowSpontaneous','var')
            if ~isempty(timeWindowSpontaneous)
                indsWindowSpontaneous=find((tdata>timeWindowSpontaneous(1)) & tdata<timeWindowSpontaneous(2));
                tWindowSpontaneous=tdata(indsWindowSpontaneous);
                VWindowSpontaneous=Vdata(indsWindowSpontaneous,7);
                IWindowSpontaneous=Iappdata(indsWindowSpontaneous,7);
            end
        end
                if exist('timeWindow1Longer','var')
            if ~isempty(timeWindow1Longer)
                indsWindow1Longer=find((tdata>timeWindow1Longer(1)) & tdata<timeWindow1Longer(2));
                tWindow1Longer=tdata(indsWindow1Longer);
                VWindow1Longer=Vdata(indsWindow1Longer,VSeriesStepOneLongerinds);
                IWindow1Longer=Iappdata(indsWindow1Longer,VSeriesStepOneLongerinds);
            end
        end
        
        
        if SHOWFIGS
            figure
            for i=1:length(VSeriesStepOneinds)
                plot(tWindow,VWindow(:,i))
                hold on
            end
            
            for i=1:length(VSeriesStepTwoinds)
                plot(tWindow2,VWindow2(:,i))
                hold on
            end
            if exist('timeWindowSpontaneous','var')
                if exist('timeWindowSpontaneous','var')
                    if ~isempty(timeWindowSpontaneous)
                        plot(tWindowSpontaneous,VWindowSpontaneous)
                    end
                end
            end
        end
        
        for i=1:length(VSeriesStepOneinds)
            tdata=tWindow; % overwriting previous values
            y=VWindow(:,i);
            Iappdata=IWindow(:,i);
            % preserve sampling rate near step transition
            inds_near_shift=[StepOne-100:StepOne+300];
            if ~(ismember(inds_near_shift(1),indsWindow) && ...
                    ismember(inds_near_shift(end),indsWindow))
                error('Preserved data isnt in window');
            else
                itemp= find(inds_near_shift(1)==indsWindow);
                inds_near_shift_window=itemp:itemp+length(inds_near_shift)-1;
            end
            if dsfAll
                inds=1:dsf:length(y);
                yout=y(inds);
                tout=tdata(inds);
            else
                [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,30,dsf,1,inds_near_shift_window,SHOWFIGS);
            end
            Iappdatanew=Iappdata(inds);
            inds=reshape(inds,length(inds),1);
            Iappdatanew=reshape(Iappdatanew/1e3,length(inds),1); %scaling factor
            tout=reshape(tout,length(tout),1);
            yout=reshape(yout,length(yout),1);
            
            filenameNew=[filenameshort,dateinfo,'_SeriesData',num2str(i),'_', 'DSF_',num2str(dsf)];
            filenameNew=[saveDir,'\',filenameNew,'.csv'];
            dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
            dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
%             movefile(filenameNew)
             [pfilenameNew,nfilenameNew,efilenameNew]=fileparts(filenameNew);
            vseriesCollection{i}=nfilenameNew;
            totalpts=totalpts+length(tout);
            
        end
        % do the same for the data window after release of step
        for i=1:length(VSeriesStepTwoinds)
            tdata=tWindow2;
            y=VWindow2(:,i);
            Iappdata=IWindow2(:,i);
            inds_near_shift=[StepTwo-100:StepTwo+300];
            if ~(ismember(inds_near_shift(1),indsWindow2) && ...
                    ismember(inds_near_shift(end),indsWindow2))
                error('Preserved data isnt in window');
            else
                itemp= find(inds_near_shift(1)==indsWindow2);
                inds_near_shift_window=itemp:itemp+length(inds_near_shift)-1;
            end
            if dsfAll
                inds=1:dsf:length(y);
                yout=y(inds);
                tout=tdata(inds);
            else
                [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,30,dsf,1,inds_near_shift_window,SHOWFIGS);
            end
            Iappdatanew=Iappdata(inds);
            inds=reshape(inds,length(inds),1);
            Iappdatanew=reshape(Iappdatanew/1e3,length(inds),1);
            tout=reshape(tout,length(tout),1);
            yout=reshape(yout,length(yout),1);
            
            filenameNew=[filenameshort,dateinfo,'_SeriesData',num2str(i),'_ReturnStep_', 'DSF_',num2str(dsf)];
            filenameNew=[saveDir,'\',filenameNew,'.csv'];
            dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
            dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
%             movefile(filenameNew)
             [pfilenameNew,nfilenameNew,efilenameNew]=fileparts(filenameNew);
            vseriesCollection{i+length(VSeriesStepOneinds)}=nfilenameNew;
            totalpts=totalpts+length(tout);
        end
        if exist('VSeriesStepOneStepTwoinds','var')
            for i=1:length(VSeriesStepOneStepTwoinds)
                tdata=tWindowAll; % overwriting previous values
                y=VWindowAll(:,i);
                Iappdata=IWindowAll(:,i);
                % preserve sampling rate near step transition
                inds_near_shift1=[StepOne-100:StepOne+300];
                inds_near_shift2=[StepTwo-100:StepTwo+300];
                
                if ~(ismember(inds_near_shift1(1),indsWindowAll) && ...
                        ismember(inds_near_shift1(end),indsWindowAll))
                    error('Preserved data isnt in window');
                else
                    itemp= find(inds_near_shift1(1)==indsWindowAll);
                    inds_near_shift_window1=itemp:itemp+length(inds_near_shift1)-1;
                end
                
                if ~(ismember(inds_near_shift2(1),indsWindowAll) && ...
                        ismember(inds_near_shift2(end),indsWindowAll))
                    error('Preserved data isnt in window');
                else
                    itemp= find(inds_near_shift2(1)==indsWindowAll);
                    inds_near_shift_window2=itemp:itemp+length(inds_near_shift2)-1;
                    inds_near_shift_window = [inds_near_shift_window1 inds_near_shift_window2];
                end
                if dsfAll
                    inds=1:dsf:length(y);
                    yout=y(inds);
                    tout=tdata(inds);
                else
                    [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,30,dsf,1,inds_near_shift_window,SHOWFIGS);
                end
                Iappdatanew=Iappdata(inds);
                inds=reshape(inds,length(inds),1);
                Iappdatanew=reshape(Iappdatanew/1e3,length(inds),1); %scaling factor
                tout=reshape(tout,length(tout),1);
                yout=reshape(yout,length(yout),1);
                
                filenameNew=[filenameshort,dateinfo,'_SeriesData',num2str(i),'_BothSteps_', 'DSF_',num2str(dsf)];
                filenameNew=[saveDir,'\',filenameNew,'.csv'];
                dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
                dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
%                 movefile(filenameNew)
                 [pfilenameNew,nfilenameNew,efilenameNew]=fileparts(filenameNew);
                vseriesCollection{i+length(VSeriesStepOneinds)+length(VSeriesStepTwoinds)}=nfilenameNew;
                totalpts=totalpts+length(tout);
            end
        end
        if exist('timeWindowSpontaneous','var')
            if ~isempty(timeWindowSpontaneous)
                tdata=tWindowSpontaneous;
                y=VWindowSpontaneous;
                Iappdata=IWindowSpontaneous;
                if dsfAll
                    inds=1:dsf:length(y);
                    yout=y(inds);
                    tout=tdata(inds);
                else
                    [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,30,dsf);
                end
                Iappdatanew=Iappdata(inds);
                inds=reshape(inds,length(inds),1);
                Iappdatanew=reshape(Iappdatanew/1e3,length(inds),1);
                tout=reshape(tout,length(tout),1);
                yout=reshape(yout,length(yout),1);
                
                filenameNew=[filenameshort,dateinfo,'_SeriesData',num2str(7),'_Spontaneous_', 'DSF_',num2str(dsf)];
                filenameNew=[saveDir,'\',filenameNew,'.csv'];
                dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
                dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
%                 movefile(filenameNew)
                [pfilenameNew,nfilenameNew,efilenameNew]=fileparts(filenameNew);
                vseriesCollection{end+1}=nfilenameNew;
                totalpts=totalpts+length(tout);
            end
        end
        
        if exist('timeWindow1Longer','var')
            if ~isempty(timeWindow1Longer)
         for i=1:length(VSeriesStepOneLongerinds)
            tdata=tWindow1Longer; % overwriting previous values
            y=VWindow1Longer(:,i);
            Iappdata=IWindow1Longer(:,i);
            % preserve sampling rate near step transition
            inds_near_shift=[StepOne-100:StepOne+300];
            if ~(ismember(inds_near_shift(1),indsWindow1Longer) && ...
                    ismember(inds_near_shift(end),indsWindow1Longer))
                error('Preserved data isnt in window');
            else
                itemp= find(inds_near_shift(1)==indsWindow1Longer);
                inds_near_shift_window=itemp:itemp+length(inds_near_shift)-1;
            end
            if dsfAll
                inds=1:dsf:length(y);
                yout=y(inds);
                tout=tdata(inds);
            else
                [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,30,dsf,1,inds_near_shift_window,SHOWFIGS);
            end
            Iappdatanew=Iappdata(inds);
            inds=reshape(inds,length(inds),1);
            Iappdatanew=reshape(Iappdatanew/1e3,length(inds),1); %scaling factor
            tout=reshape(tout,length(tout),1);
            yout=reshape(yout,length(yout),1);
            
            filenameNew=[filenameshort,dateinfo,'_SeriesData',num2str(i),'_', 'DSF_',num2str(dsf)];
            filenameNew=[saveDir,'\',filenameNew,'.csv'];
            dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
            dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
%             movefile(filenameNew)
            [pfilenameNew,nfilenameNew,efilenameNew]=fileparts(filenameNew);
            vseriesCollection{end+1}=nfilenameNew;
            totalpts=totalpts+length(tout);
         end
            end
        end
    else
        dataA=csvread(filename,1,0);
        Iapp =dataA(:,3); % N x NumVoltageObs
        y=dataA(:,4);
        Iappdata = reshape(Iapp,length(Iapp),1);
        
        tdata =dataA(:,2);
        [tout,yout,inds] = downsample_from_threshold(tdata,y,-20,25,dsf);
        WindowUse=1:ceil((2/10)*length(tout));
        tout=tout(WindowUse);
        yout=yout(WindowUse);
        inds=inds(WindowUse);
        Iappdatanew=Iappdata(inds);
        inds=reshape(inds,length(inds),1);
        Iappdatanew=reshape(Iappdatanew,length(inds),1);
        tout=reshape(tout,length(tout),1);
        yout=reshape(yout,length(yout),1);
        
        filenameNew=[filenameshort, 'DSF_',num2str(dsf)];
        filenameNew=[saveDir,'\',filenameNew,'.csv'];
        dlmwrite(filenameNew,'Index, time (ms), I0 (pA), V0 (mV)');
        dlmwrite(filenameNew,[inds, tout, Iappdatanew,yout],'-append','precision',8)
        
        
    end
    
    
    % The csvfile structure is [Index, time (ms), I (pA), V (mV)]
    % We have implemented that applied current, I (pA) will be scaled by a
    % factor of 10^-3 consistent with the drosophila data. This is scaled back
    % prior to the 4D-Var problem initiation.
    
    %%
    % Specify the model using the casadi symbolic framework.
    %%
    % if UseReduced
    % ODEmodel=@casadi_Belle2009_new_reduced;
    % else
    %  ODEmodel=@casadi_Belle2009_new;
    % end
    % Now we pass these as arguments to our initiation function for 4D-Var.
    % The choice to encapsulate this in another function is for ease with
    % running in batch with KONG for various initial conditions (multi-start).
    
    
    switch modeltouse
        case 1
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new','_case',num2str(CASE),'.mat'];
            
            PDATA=PDATA_new;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new;
            
        case 2
            Nstate=5;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_fastm','_case',num2str(CASE),'.mat'];
            PDATA=PDATA_new_fastm;
            ODEmodel=@casadi_Belle2009_new_fastm;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            
        case 3
            modelDataFileName='data_SCN_new_reduced.mat';
            PDATA=PDATA_new_reduced;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_reduced;
        case 4
            Nstate=5;
            nleaks=2;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_fastm_twoleak','_case',num2str(CASE),'.mat'];
            PDATA=PDATA_new_fastm_twoleak;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_fastm_twoleak;
        case 5
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_mtau','_case',num2str(CASE),'.mat'];
            PDATA=PDATA_new_mtau;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_mtau;
        case 6
            Nstate=5;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_mtau_fastm','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_mtau_fastm;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_mtau_fastm;
        case 6.5
            Nstate=5;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_mtau_fastm_twoleaks','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_mtau_fastm_twoleaks;
            ODEmodel=@casadi_Belle2009_new_mtau_fastm_twoleaks;
            
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            ODEmodel=@casadi_Belle2009_new_mtau_fastm_twoleaks;
            
        case 7
            Nstate=6;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_taus_constant','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_taus_constant;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_taus_constant;
            
            
            
        case 8
            Nstate=5;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_fastm_taus_constant','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_fastm_taus_constant;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection');
            ODEmodel=@casadi_Belle2009_new_fastm_taus_constant;
            
        case 9
            Nstate=7;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_IaIh_v1','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_IaIh_v1;
            ODEmodel=@casadi_Belle2009_IaIh_v1;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            %   ODEmodel=@casadi_Belle2009_IaIh_v1;
        case 10
            Nstate=6;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_Ia_v1','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_Ia_v1;
            ODEmodel=@casadi_Belle2009_Ia_v1;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            %   ODEmodel=@casadi_Belle2009_IaIh_v1;
        case 11
            Nstate=7;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_Ia_v2','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_Ia_v2;
            ODEmodel=@casadi_Belle2009_Ia_v2;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            %   ODEmodel=@casadi_Belle2009_IaIh_v1;
        case 12
            Nstate = 7;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_IaIh_tauall','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_twoleaks_IaIh_tauall;
            ODEmodel=@casadi_Belle2009_IaIh_tauall;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
                    case 12.1
                        Nstate = 7;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_IaIh_tauall_oneleak','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_IaIh_tauall;
            ODEmodel=@casadi_Belle2009_IaIh_tauall_oneleak;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
        case 13
            Nstate = 8;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_IaIhInap_tauall','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_twoleaks_IaIhInap_tauall;
            ODEmodel=@casadi_Belle2009_IaIhInap_tauall;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
        case 14
            Nstate=6;
            modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_Ih_tauall','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_twoleaks_Ih_tauall;
            ODEmodel=@casadi_Belle2009_Ih_tauall;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
        case 15
                        modelDataFileName=[saveDir, '\', mDFN_prefix,'data_SCN_new_Ia_tauall','_case',num2str(CASE)];
            modelDataFileName=strrep(modelDataFileName,'.','pt');
            PDATA=PDATA_new_twoleaks_Ia_tauall;
            ODEmodel=@casadi_Belle2009_Ia_tauall_twoleak;
            save(modelDataFileName,'PDATA','Nstate','compartments','nleaks','vseriesCollection','ODEmodel');
            
    end
    
    totalpts*(Nstate+1)
end
% DATA= {filename1,filename2}


% %%
% % change linear_solver value: 'ma_57' to 'mumps' if ma57 not installed.
% for SeedNum=511:520
% run_Run_ODE_4dvar_multiple_collocation(SeedNum,vseriesCollection,modeldata,ODEmodel,  ...
%     'UseControl',0,'SmoothControl',0,'ControlPenalty',1,'yinds',1,'TOL',1e-10,...
%     'METHODTOUSE','Strong','varannealbounds',[0,70],'hessian_approximation','exact',...
%     'ControlAtEnd',0,'linear_solver','mumps','SaveLagGrad',0,'UseSlack',1,'UseAdaptive',1,...
%     'correctLJPData',0,'alpha0',1.5,'UseColpack',1,'ScaleSlack',1','ScaleConstraints',0)
% end
%
%

