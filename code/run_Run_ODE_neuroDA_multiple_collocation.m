function [] =run_Run_ODE_neuroDA_multiple_collocation(SeedNum,DATAFLAG,modeldata,ODEmodel,varargin)
if nargin>4
    VarLoc = find(strcmpi(varargin, 'METHODTOUSE'));
    if ~isempty(VarLoc)
        METHODTOUSE = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        METHODTOUSE='Strong';
    end
    VarLoc = find(strcmpi(varargin, 'varannealbounds'));
    if ~isempty(VarLoc)
        varannealbounds = varargin{VarLoc(1)+1}; %Get the value after the param name
        varannealmin=varannealbounds(1);
        varannealmax=varannealbounds(2);
    else
        varannealmin=30;
        varannealmax=30;
    end
    VarLoc = find(strcmpi(varargin, 'UseControl'));
    if ~isempty(VarLoc)
        UseControl = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        UseControl=1;
    end
    VarLoc = find(strcmpi(varargin, 'dt'));
    if ~isempty(VarLoc)
        dt = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        dt=0.02;
    end
    VarLoc = find(strcmpi(varargin, 'ControlPenalty'));
    if ~isempty(VarLoc)
        ControlPenalty = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ControlPenalty=1;
    end
    VarLoc = find(strcmpi(varargin, 'ControlPower'));
    if ~isempty(VarLoc)
        ControlPower = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ControlPower=2;
    end
    VarLoc = find(strcmpi(varargin, 'SaveHess'));
    if ~isempty(VarLoc)
        SaveHess = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        SaveHess=0;
    end
    VarLoc = find(strcmpi(varargin, 'SaveLagGrad'));
    if ~isempty(VarLoc)
        SaveLagGrad = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        SaveLagGrad=0;
    end
    VarLoc = find(strcmpi(varargin, 'SmoothControl'));
    if ~isempty(VarLoc)
        SmoothControl = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        SmoothControl=0;
    end
    
    VarLoc = find(strcmpi(varargin, 'yinds'));
    if ~isempty(VarLoc)
        yinds = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        yinds=1;
    end
    
    VarLoc = find(strcmpi(varargin, 'TSSinds'));
    if ~isempty(VarLoc)
        TSSinds = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        TSSinds=0;
    end
    
    
    VarLoc = find(strcmpi(varargin, 'TOL'));
    if ~isempty(VarLoc)
        TOL = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        TOL=1e-12;
    end
    
    VarLoc = find(strcmpi(varargin, 'xbounds'));
    if ~isempty(VarLoc)
        xbounds = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        xbounds=[];
    end
    
    VarLoc = find(strcmpi(varargin, 'hessian_approximation'));
    if ~isempty(VarLoc)
        hessian_approximation = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        hessian_approximation='exact';
    end
    
    VarLoc = find(strcmpi(varargin, 'ControlAtEnd'));
    if ~isempty(VarLoc)
        ControlAtEnd = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ControlAtEnd=1;
    end
    
    VarLoc = find(strcmpi(varargin, 'linear_solver'));
    if ~isempty(VarLoc)
        linear_solver = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        linear_solver='mumps';
    end
    
    VarLoc = find(strcmpi(varargin, 'UseAdaptive'));
    if ~isempty(VarLoc)
        UseAdaptive = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        UseAdaptive=0;
    end
    
    VarLoc = find(strcmpi(varargin, 'correctLJPData'));
    if ~isempty(VarLoc)
        correctLJPData = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        correctLJPData=0;
    end
    
        VarLoc = find(strcmpi(varargin, 'alpha0'));
    if ~isempty(VarLoc)
        alpha0 = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        alpha0=2;
    end
        
    VarLoc = find(strcmpi(varargin, 'UseSlack'));
    if ~isempty(VarLoc)
        UseSlack = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        UseSlack=0;
    end
        VarLoc = find(strcmpi(varargin, 'UseColpack'));
    if ~isempty(VarLoc)
        UseColpack = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        UseColpack=1;
    end
    
            VarLoc = find(strcmpi(varargin, 'ScaleVariables'));
    if ~isempty(VarLoc)
        ScaleVariables = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ScaleVariables=0;
    end
                    VarLoc = find(strcmpi(varargin, 'ScaleConstraints'));
    if ~isempty(VarLoc)
        ScaleConstraints = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ScaleConstraints=1;
    end
    
                        VarLoc = find(strcmpi(varargin, 'ScaleSlack'));
    if ~isempty(VarLoc)
        ScaleSlack = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ScaleSlack=0;
    end
    
                            VarLoc = find(strcmpi(varargin, 'saveDir'));
    if ~isempty(VarLoc)
        saveDir = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        saveDir='';
    end
    
        
                            VarLoc = find(strcmpi(varargin, 'PenalizeSlope'));
    if ~isempty(VarLoc)
        PenalizeSlope = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        PenalizeSlope=0;
    end
    
    VarLoc= find(strcmpi(varargin, 'RunWithoutControl'));
    if ~isempty(VarLoc)
        RunWithoutControl = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        RunWithoutControl=0;
    end
    
        VarLoc= find(strcmpi(varargin, 'RampUpControl'));
    if ~isempty(VarLoc)
        RampUpControl = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        RampUpControl=0;
    end
    
            VarLoc= find(strcmpi(varargin, 'ControlBound'));
    if ~isempty(VarLoc)
        ControlBound = varargin{VarLoc(1)+1}; %Get the value after the param name
    else
        ControlBound=1;
    end
end


%yinds=1;
%correctLJPData=0;
% if (strcmp(DATAFLAG(1:4),'2011')) || (strcmp(DATAFLAG(1:4),'2012')) ||...
%         (strcmp(DATAFLAG(1:4),'2010')) || (strcmp(DATAFLAG(1:4),'2009'))
%     yinds=0;
%     correctLJPData=1;
% end
if strcmp(DATAFLAG,'April8')
    % DATAFLAG={'2011_04_08_0001','2011_04_08_0002','2011_04_08_0003','2011_04_08_0004'};
    DATAFLAG={'2011_04_08_0001','2011_04_08_0002','2011_04_08_0003','2011_04_08_0004'};
    %DATAFLAG = '2011_04_08_0002.csv';
    yinds=0;
    correctLJPData=1;
elseif strcmp(DATAFLAG,'April28')
    DATAFLAG={'2011_04_28_0036','2011_04_28_0037','2011_04_28_0038','2011_04_28_0039'};
    yinds=0;
    correctLJPData=1;
elseif strcmp(DATAFLAG,'April29')
    DATAFLAG={'2011_04_29_0006','2011_04_29_0007','2011_04_29_0008','2011_04_29_0009'};
    yinds=0;
    correctLJPData=1;
elseif strcmp(DATAFLAG,'December21')
    DATAFLAG={'2011_12_21_0002','2011_12_21_0005'};
    yinds=0;
    correctLJPData=1;
end
%defaultParameters=struct('init_C',1,'init_Es',[50 -77 -54.4],'init_Gs',[120 20 .3]);

load(modeldata,'PDATA','Nstate','compartments','nleaks')
if strcmp(DATAFLAG,'UseModelData')
    load(modeldata,'vseriesCollection');
    DATAFLAG=vseriesCollection;
end
defaultp=PDATA(:,3);
parambounds=PDATA(:,1:2);
Kinactivation=0;
%ControlInfo=[0 100 1e0 0];
ControlInfo=[0 ControlBound ControlPenalty 0 ControlPower];
pest_ind= find(PDATA(:,1)~=PDATA(:,2));
%Kinactivation=1;
%dt_col=.1;
Run_ODE_neuroDA_with_collocation(SeedNum,DATAFLAG,struct('MethodToUse'...
    ,METHODTOUSE,'varAnnealMin',varannealmin,'varAnnealMax',varannealmax,...
    'yinds',yinds,'defaultp',defaultp,'pest_ind',pest_ind,'Kinactivation',Kinactivation,...
    'UseControl',UseControl,'MAXITER',2500,'linear_solver',linear_solver,...
    'ACCEPTABLE_TOL',1e-6,'obj_scaling_factor',1,'TOL',TOL,...
    'mumps_mem_percent',1000,'mumps_pivtol',1e-8,'mumps_pivtolmax',1e-1,...
    'nlp_scaling_max_gradient',1,'max_hessian_perturbation',10^5,...
    'ScaleConstraints',ScaleConstraints,'ControlInfo',ControlInfo,'paramsBounded',1,...
    'dtmodel',dt,'DT',dt,'IntegrationScheme','SimpsonHermite',...
    'DisplayIter',0,'ControlAtEnd',ControlAtEnd,...
    'hessian_approximation',hessian_approximation,...
    'SaveHess',SaveHess,'SaveLagGrad',SaveLagGrad,'FixValqt',0,'alpha0',alpha0,...
    'modeleqns',ODEmodel,'parambounds',parambounds,'Nstate',Nstate,...
    'correctLJPData',correctLJPData,'compartments',compartments,...
    'SmoothControl',SmoothControl,'TSSinds',TSSinds,'xbounds',xbounds,...
    'UseAdaptive',UseAdaptive,'UseSlack',UseSlack,'UseColpack',UseColpack,...
    'ScaleVariables',ScaleVariables,'ScaleSlack',ScaleSlack,'saveDir',saveDir,...
    'PenalizeSlope',PenalizeSlope,'RunWithoutControl',RunWithoutControl,...
    'RampUpControl',RampUpControl))
end