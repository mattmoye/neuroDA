function [outputFileName,fighandles,titleName] = eval_rhabdomys_ests_neuroDA(filename,varargin)

%add(genpath('~/Dropbox/Shared-Folders/Matt - Casey'))

%% Evaluation script
if nargin>1
    FlagStruct=varargin{1};
    if ~isfield(FlagStruct,'ODESOLVER')
        FlagStruct.ODESOLVER=@ode45;
    end
    if nargin>2
        dataDir=varargin{2};
    else
        dataDir=[pwd, '\', 'rawData\rhabdomys\Hyper-Depo-Pulses\'];
    end
else
    FlagStruct=struct('MakeFigs',0,'SaveData',1,'ODESOLVER',@ode45);
    dataDir=[pwd, '\', '\rawData\rhabdomys\Hyper-Depo-Pulses\'];

end
try
    load(filename,'beta','FileName','dataFileName','fval','guess','probinfo','w_opt','SeedNum','solverstats');
catch
    outputFileName='';
    return
end
% Check if is actually a minimum
if solverstats.success && (beta == probinfo.varAnnealMax)
    TrueMinima=1;
else
    TrueMinima=0;
end

ODESOLVER=FlagStruct.ODESOLVER;



iCell=strfind(dataFileName,'Cell');
izerozero=strfind(dataFileName,'00');
izerozero=izerozero(1);
cellName=dataFileName(iCell:izerozero+3);

cellNumber=dataFileName(iCell:izerozero-2);
iDate=strfind(dataFileName,'_19');
iDate=iDate(1)+1;
cellDate=dataFileName(iDate:iDate+5);
irunDate=strfind(FileName,'2020');
runDate=FileName(irunDate:end);
NightCells={'191124', '191126', '191215', '191220'};
NightFlag=sum(strcmp(cellDate,NightCells));
titleName=[cellDate,'_',cellName];
FS=8;
HyperDepoPulsesDir=dataDir;
if NightFlag
    HyperDepoPulsesDataDir=fullfile(HyperDepoPulsesDir,['Night_',cellDate,'_Pulses'],'matFiles');
else
    HyperDepoPulsesDataDir=fullfile(HyperDepoPulsesDir,[cellDate,'_Pulses'],'matFiles');
end

if strfind(FileName,'Redo')
SeedNum=SeedNum*100; %just to denote larger one.
end
IappStepVec=-30:5:30;
StepOne=2.6641e4; % when the change occurs.
StepTwo=5.1641e4; % when the second change occurs
StepTwoPlus=StepTwo+1e4;
if isfile(fullfile(HyperDepoPulsesDataDir,[cellName,'.mat']))
CCfilename=fullfile(HyperDepoPulsesDataDir,[cellName,'.mat']);
elseif    isfile(fullfile(HyperDepoPulsesDataDir,[[cellName(1:4),'_',cellName(5:end)],'.mat']))
     CCfilename=fullfile(HyperDepoPulsesDataDir,[cellName,'.mat']);
else
    error('Cannot find the file');
end
if NightFlag
    CCdata=load(CCfilename,'ObsData','tdata','ControlData');
    CCdata.Vdata=CCdata.ObsData;
    CCdata.Iappdata=CCdata.ControlData;
else
CCdata=load(CCfilename,'Vdata','tdata','Iappdata');
end
dtdata=CCdata.tdata(2)-CCdata.tdata(1);

if FlagStruct.MakeFigs
    close(figure(1))
    close(figure(2))
    close(figure(3))
    close(figure(4))
end

%% Let's not waste computational time redoing the same trials.

outputFileName=[cellDate,'_',cellName,'_estimate_comparison.mat'];
fulloutFileName=fullfile(pwd,outputFileName);

% if FlagStruct.SaveData
%     if exist(fulloutFileName,'file')
%         load(fulloutFileName,'compStruct');
%         
%         for jj=1:length(compStruct)
%             if abs(compStruct(jj).fval-fval) < 1e-6
%                 newcompStruct=compStruct(jj);
%                 newcompStruct.SeedNum=SeedNum;
%                 newcompStruct.runDate=runDate;
%                 compStruct=[compStruct newcompStruct];
%                 save(fulloutFileName,'compStruct');
%                 return
%             end
%         end
%     end
% end

%% Current clamp, real data
nCC=length(IappStepVec);
for i=1:nCC
    VdataPulse=CCdata.Vdata(StepOne:StepTwoPlus,i);
    tdataPulse=CCdata.tdata(StepOne:StepTwoPlus);
    Vdatafull=CCdata.Vdata(:,i);
    tdatafull=CCdata.tdata(:);
    [pks,locs,widths,amps]=findpeaks(VdataPulse,tdataPulse,'MinPeakProminence',15,'MinPeakDistance',5);
     %   [pks,locs,widths,amps]=findpeaks(Vdatafull,tdatafull,'MinPeakProminence',15,'MinPeakDistance',5);
            if i == 1
                    [pkst,locst,widthst,ampst]=findpeaks(Vdatafull,tdatafull,'MinPeakProminence',15,'MinPeakDistance',5);

                FirstSpikeData=locst(locst>tdatafull(StepTwo)); 
                if isempty(FirstSpikeData)
                    FirstSpikeData=Inf;
                else
                FirstSpikeData=FirstSpikeData(1);
                end
            end
    if FlagStruct.MakeFigs
        figure(1)
        sgtitle({titleName},'FontSize',24,'Interpreter','none')
        
        subplot(4,4,i)
        hold on
        plot(CCdata.tdata,CCdata.Vdata(:,i),locs,pks,'ro','LineWidth',2);
    end
    fr_data(i)=length(pks)/(tdataPulse(end)-tdataPulse(1));
   % fr_data(i)=length(pks)/(tdatafull(end)-tdatafull(1));
end

% %% Voltage clamp, real data NEEDS EDITING
% VCCurrentsDir=[dropbox,'\Matt - Casey\rhabdomys\VC-Currents\'];
% if ~NightFlag
%     VCCurrentsDataDir=fullfile(VCCurrentsDir,cellDate,[cellDate,'_',cellNumber],'matFiles');
%     a=dir(fullfile(VCCurrentsDataDir,'*.mat'));
%     VCfilename=fullfile(VCCurrentsDataDir,a(1).name); % assumes ordered correctly
%     VCdata=load(VCfilename);
% end
%% Current-clamp experiments, using our model
Numleaks=1;
UseIH=0;
UseITO=0;
UseINap=0;
switch func2str(probinfo.modeleqns)
    case 'casadi_Belle2009_new_mtau_fastm'
        ODE_RHS=@ode_Belle2009_new_mtau_fastm;
        CurrentFunction=@currents_Belle2009_new_mtau_fastm;
    case 'casadi_Belle2009_new_mtau_fastm_twoleaks'
        ODE_RHS=@ode_Belle2009_new_mtau_fastm_twoleaks;
        CurrentFunction=@currents_Belle2009_new_mtau_fastm_twoleaks;
        ssfunctions=@functions_Belle2009_new_mtau_fastm_twoleaks;
        Numleaks=2;
    case 'casadi_Belle2009_new_taus_constant'
        ODE_RHS=@ode_Belle2009_new_taus_constant;
        CurrentFunction=@currents_Belle2009_new_taus_constant;
    case 'casadi_Belle2009_new_fastm_taus_constant'
        ODE_RHS=@ode_Belle2009_new_fastm_taus_constant;
        CurrentFunction=@currents_Belle2009_new_fastm_taus_constant;
    case 'casadi_Belle2009_IaIh_v1'
        ODE_RHS=@ode_Belle2009_IaIh_v1;
        CurrentFunction=@currents_Belle2009_IaIh_v1;
        Numleaks=2;
        UseIH=1;
        UseITO=1;
        
            case 'casadi_Belle2009_Ia_v1'
        ODE_RHS=@ode_Belle2009_Ia_v1;
        CurrentFunction=@currents_Belle2009_Ia_v1;
        Numleaks=2;
        UseIH=0;
        UseITO=1;
        
            case 'casadi_Belle2009_Ia_v2'
        ODE_RHS=@ode_Belle2009_Ia_v2;
        CurrentFunction=@currents_Belle2009_Ia_v2;
        Numleaks=2;
        UseIH=0;
        UseITO=1;
    case 'casadi_Belle2009_IaIh_tauall'
        ODE_RHS=@ode_Belle2009_IaIh_tauall;
        CurrentFunction=@currents_Belle2009_IaIh_tauall;
        ssfunctions=@functions_Belle2009_IaIh_tauall;
        Numleaks=2;
        UseIH=1;
        UseITO=1;
        
            case 'casadi_Belle2009_IaIh_tauall_oneleak'
        ODE_RHS=@ode_Belle2009_IaIh_tauall_oneleak;
        CurrentFunction=@currents_Belle2009_IaIh_tauall_oneleak;
        ssfunctions=@functions_Belle2009_IaIh_tauall_oneleak;
        Numleaks=1;
        UseIH=1;
        UseITO=1;
    case  'casadi_Belle2009_IaIhInap_tauall'
        ODE_RHS=@ode_Belle2009_IaIhInap_tauall;
                CurrentFunction=@currents_Belle2009_IaIhInap_tauall;
                ssfunctions=@functions_Belle2009_IaIhInap_tauall;
        Numleaks=2;
        UseIH=1;
        UseITO=1;
        UseINap=1;
    case 'casadi_Belle2009_Ih_tauall'
                ODE_RHS=@ode_Belle2009_Ih_tauall;
        CurrentFunction=@currents_Belle2009_Ih_tauall;
        ssfunctions=@functions_Belle2009_Ih_tauall;
        Numleaks=2;
        UseIH=1;
        UseITO=0;
            case 'casadi_Belle2009_Ia_tauall_twoleak'
                ODE_RHS=@ode_Belle2009_Ia_tauall;
        CurrentFunction=@currents_Belle2009_Ia_tauall;
        ssfunctions=@functions_Belle2009_Ia_tauall;
        Numleaks=2;
        UseIH=0;
        UseITO=1;      
    otherwise
        error('Model not implemented');
end


t=CCdata.tdata;
x0=probinfo.xt(1:probinfo.Nstate);

%%%%%% HOW TO EXTRACT THE PARAMETERS %%%%%%
pest=w_opt(end-length(probinfo.defaultp)+1:end);

%pest(8)=1.14*pest(8);
if TrueMinima
    f=@(t,x,Iapp)ODE_RHS(t,x,pest,Iapp);
    
    for i=1:nCC
        Iapp=zeros(size(CCdata.tdata));
        Iapp(StepOne:StepTwo)=IappStepVec(i);
        x0use=reshape(x0,length(x0),1);
        ttotal=[]; xtotal=[];
        %     [stepsidx,val]=find(abs(diff(Iapp))>1);
        %     stepsidx=[1 stepsidx'+1 length(Iapp)];
        stepsidx=[1 StepOne StepTwo length(Iapp)+1];
        %for i=1:length(time)-1
        ModelTooStiff=0;
        for ii =1:length(stepsidx)-1
            f1=@(t,x)f(t,x,Iapp(stepsidx(ii)+1));
            try 
                tic
            [t1,x1]=ODESOLVER(f1,t(stepsidx(ii):stepsidx(ii+1)-1),x0use);
            tocval=toc;
            catch 
                ModelTooStiff=1;
                break;
            end
            if isnan(x1)
                ModelTooStiff=1;
                break
                
            end
            if tocval > 5
                ModelToStiff=1;
                break
            end
            x0use=x1(end,:)';
            ttotal=[ttotal; t1(1:end,:)];
            xtotal=[xtotal; x1(1:end,:)];
        end
        if ~ModelTooStiff
            Vest(:,i)=xtotal(:,1);
            
            try
            [pks,locs,widths,amps]=findpeaks(Vest(StepOne:StepTwoPlus,i),ttotal(StepOne:StepTwoPlus),'MinPeakProminence',15,'MinPeakDistance',5);
            catch
                ModelTooStiff=1;
                break
            end
        end
            if ~ModelTooStiff
           %            [pks,locs,widths,amps]=findpeaks(Vest(:,i),ttotal(:),'MinPeakProminence',15,'MinPeakDistance',5);
      
            if i == 1
                [pkst,locst,widthst,ampst]=findpeaks(Vest(:,i),ttotal(:),'MinPeakProminence',15,'MinPeakDistance',5);

                FirstSpikeModel=locst(locst>ttotal(StepTwo)); 
                if isempty(FirstSpikeModel)
                    FirstSpikeModel=Inf;
                else
                FirstSpikeModel=FirstSpikeModel(1);
                end
                end
            if FlagStruct.MakeFigs
               h1= figure(1);
                grid on
                subplot(4,4,i)
                plot(ttotal,Vest(:,i),'Color',[0.8500, 0.3250, 0.0980],'LineWidth',2)
                hold on
                plot(locs,pks,'go');
                ylabel('Voltage (mV)','FontSize',FS,'Interpreter','Latex')
                xlabel('Time (ms)','FontSize',FS,'Interpreter','Latex')
                %legend({'Estimate','Original'},'FontSize',FS)
                % title({titleName},'FontSize',24)
                
                if i==7
              h3=      figure(3);
                   grid on 
                    plot(CCdata.Vdata(:,i),gradient(CCdata.Vdata(:,i),dtdata),'LineWidth',2)
                    hold on
                    
                    plot(xtotal(:,1),gradient(xtotal(:,1),ttotal(2)-ttotal(1)),'LineWidth',2)
                    
                    xlabel('Voltage (mV)','FontSize',20,'Interpreter','Latex')
                    ylabel('dV/dt (mV/ms)','FontSize',20,'Interpreter','Latex')
                    legend({'Original','Estimate'},'FontSize',20)
                    title({titleName},'FontSize',24,'Interpreter','none')
                    set(gcf,'Position',get(0,'Screensize'));
                end
                
            end
            fr_est(i)=length(pks)/(ttotal(StepTwoPlus)-ttotal(StepOne));
           % fr_est(i) = length(pks)/(ttotal(end)-ttotal(1));
            if FlagStruct.MakeFigs
                CurrentStruct=CurrentFunction(ttotal,xtotal,pest,Iapp);
            h2=    figure(2);
                grid on 
                sgtitle({titleName},'FontSize',24,'Interpreter','none')
                
                subplot(4,4,i)
                totalLines=numel(fieldnames(CurrentStruct))+1; % plus 1 for voltage
                mycolors=distinguishable_colors(totalLines);
                idxc=1;
                Ina=CurrentStruct.INa;
                Ik=CurrentStruct.IK;
                Ica=CurrentStruct.ICa;
                legendToUse={'Voltage','Ina','Ik','Ica'};
                if Numleaks==1
                Il=CurrentStruct.ILeak;
                else
                    Il_na = CurrentStruct.ILeak_Na;
                    Il_k = CurrentStruct.ILeak_K;
                end
                Isum=CurrentStruct.ISum;
                plot(ttotal,xtotal(:,1)*20,'--','LineWidth',2,'Color',mycolors(idxc,:))
                hold on
                plot(ttotal,Ina,'LineWidth',2,'Color',mycolors(idxc+1,:))
                hold on
                plot(ttotal,Ik,'LineWidth',2,'Color',mycolors(idxc+2,:))
                plot(ttotal,Ica,'LineWidth',2,'Color',mycolors(idxc+3,:))
                idxc=idxc+4;
                if Numleaks==1
                plot(ttotal,Il,'LineWidth',2,'Color',mycolors(idxc,:))
                plot(ttotal,Isum,'LineWidth',2,'Color',mycolors(idxc+1,:))
                idxc=idxc+2;
                legendToUse=[legendToUse {'Ileak','Isum'}];
              %  legend({'Voltage','Ina','Ik','Ica','Ileak','Isum'},'FontSize',6)
                else
                     plot(ttotal,Il_na,'LineWidth',2,'Color',mycolors(idxc,:))
                     plot(ttotal,Il_k,'LineWidth',2,'Color',mycolors(idxc+1,:))
                     idxc=idxc+2;
                plot(ttotal,Isum,'LineWidth',2)
                                legendToUse=[legendToUse {'Ileak_na','Ileak_k','Isum'}];

            %    legend({'Voltage','Ina','Ik','Ica','Ileak_na','Ileak_k','Isum'},'FontSize',6)
                end
                
                if UseIH
                    Ih = CurrentStruct.IH;
                                    plot(ttotal,Ih,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'Ih'}];
                end
                                if UseITO
                    ITO = CurrentStruct.ITO;
                                    plot(ttotal,ITO,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'Ito'}];
                                end
                                                if UseINap
                    INap = CurrentStruct.INap;
                                    plot(ttotal,INap,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'INap'}];
                end
                legend(legendToUse,'FontSize',6)
                xlabel('Voltage (mV)','FontSize',FS,'Interpreter','Latex')
                ylabel('I (pA)','FontSize',FS,'Interpreter','Latex')
                set(gcf,'Position',get(0,'Screensize'));
                if i==1 && exist('ssfunctions','var')                  
                    plot_gating_functions(ssfunctions(pest))         
                end
                if i==1
                                    CurrentStruct=CurrentFunction(ttotal,xtotal,pest,Iapp);
            h4=    figure(4);
                grid on 
                sgtitle({titleName},'FontSize',24,'Interpreter','none')
                
               % subplot(4,4,i)
                totalLines=numel(fieldnames(CurrentStruct))+1; % plus 1 for voltage
                mycolors=distinguishable_colors(totalLines);
                idxc=1;
                Ina=CurrentStruct.INa;
                Ik=CurrentStruct.IK;
                Ica=CurrentStruct.ICa;
                legendToUse={'Voltage','Ina','Ik','Ica'};
                if Numleaks==1
                Il=CurrentStruct.ILeak;
                else
                    Il_na = CurrentStruct.ILeak_Na;
                    Il_k = CurrentStruct.ILeak_K;
                end
                Isum=CurrentStruct.ISum;
                plot(ttotal,xtotal(:,1)*20,'--','LineWidth',2,'Color',mycolors(idxc,:))
                hold on
                plot(ttotal,Ina,'LineWidth',2,'Color',mycolors(idxc+1,:))
                hold on
                plot(ttotal,Ik,'LineWidth',2,'Color',mycolors(idxc+2,:))
                plot(ttotal,Ica,'LineWidth',2,'Color',mycolors(idxc+3,:))
                idxc=idxc+4;
                if Numleaks==1
                plot(ttotal,Il,'LineWidth',2,'Color',mycolors(idxc,:))
                plot(ttotal,Isum,'LineWidth',2,'Color',mycolors(idxc+1,:))
                idxc=idxc+2;
                legendToUse=[legendToUse {'Ileak','Isum'}];
              %  legend({'Voltage','Ina','Ik','Ica','Ileak','Isum'},'FontSize',6)
                else
                     plot(ttotal,Il_na,'LineWidth',2,'Color',mycolors(idxc,:))
                     plot(ttotal,Il_k,'LineWidth',2,'Color',mycolors(idxc+1,:))
                     idxc=idxc+2;
                plot(ttotal,Isum,'LineWidth',2)
                                legendToUse=[legendToUse {'Ileak_na','Ileak_k','Isum'}];

            %    legend({'Voltage','Ina','Ik','Ica','Ileak_na','Ileak_k','Isum'},'FontSize',6)
                end
                
                if UseIH
                    Ih = CurrentStruct.IH;
                                    plot(ttotal,Ih,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'Ih'}];
                end
                                if UseITO
                    ITO = CurrentStruct.ITO;
                                    plot(ttotal,ITO,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'Ito'}];
                                end
                                                if UseINap
                    INap = CurrentStruct.INap;
                                    plot(ttotal,INap,'LineWidth',2,'Color',mycolors(idxc,:))
                                    idxc=idxc+1;
                legendToUse = [legendToUse {'INap'}];
                end
                legend(legendToUse,'FontSize',6)
                xlabel('Voltage (mV)','FontSize',FS,'Interpreter','Latex')
                ylabel('I (pA)','FontSize',FS,'Interpreter','Latex')
                set(gcf,'Position',get(0,'Screensize'));
                      
                figure(5)                
                                set(gcf,'Position',get(0,'Screensize'));

            end
            end
        end
        
    end
    
    if ModelTooStiff
        fr_diff=Inf;
        fr_est=Inf;
        fr_data=Inf;
        fr_temp=Inf;
        fr_diff_weight=inf;
        first_spike_diff=Inf;
    else
        
        % Need to use log sum of absolute error because
        fr_est=fr_est*1e3;
        fr_data=fr_data*1e3;
        fr_diff=sum(abs(fr_est-fr_data));
        fr_temp=abs(fr_est-fr_data);
        fr_temp(7)=5*fr_temp(7);
        fr_diff_weight=sum(fr_temp);
        first_spike_diff=(abs(FirstSpikeData-FirstSpikeModel));
    end
else
    fr_diff=Inf;
    fval=Inf;
    fr_est=Inf;
    fr_diff_weight=Inf;
    first_spike_diff=Inf;
end

outputFileName=[cellDate,'_',cellName,'_estimate_comparison.mat'];
fulloutFileName=fullfile(pwd,outputFileName);
if FlagStruct.SaveData
    if ~exist(fulloutFileName,'file')
        compStruct=struct('fval',fval,'SeedNum',SeedNum,'fr_data',fr_data,...
            'fr_estimate',fr_est,'fr_diff',fr_diff,'fr_diff_weight',fr_diff_weight,'runDate',runDate,'first_spike_diff',first_spike_diff);
        save(fulloutFileName,'compStruct');
    else
        load(fulloutFileName,'compStruct');
        newcompStruct=struct('fval',fval,'SeedNum',SeedNum,'fr_data',fr_data,...
            'fr_estimate',fr_est,'fr_diff',fr_diff,'fr_diff_weight',fr_diff_weight,'runDate',runDate,'first_spike_diff',first_spike_diff);
        compStruct=[compStruct newcompStruct];
        save(fulloutFileName,'compStruct');
    end
end
if FlagStruct.MakeFigs
fighandles=[h1,h2,h3];
else
    fighandles=[];
end
%%
% vesti=xtotal(1,:);
% SAFETYNET=.1;
% if ~isempty(find(Iappuse> min(Iappuse)+SAFETYNET))
% spkwindow=find(Iappuse>(min(Iappuse)+SAFETYNET));
% else
%     spkwindow=1:length(vesti);
% end
% figure(192)
% plot(tin,vesti)
% hold on
%
% Vn=vesti(spkwindow);
% tn=tin(spkwindow);
% spkcnt=0;
% Vth=-20;
% for jj=1:length(Vn)-1
%     if Vn(jj+1)>=Vth && Vn(jj)<Vth
%        spkcnt = spkcnt+1;
%      %  tspks(spkcnt,i+1)=t(j);
%     %  tspkidxs(spkcnt)=j;
%    end
% end
% SPKCNT(i)=spkcnt;