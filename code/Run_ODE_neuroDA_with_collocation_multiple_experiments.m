function [] = Run_ODE_neuroDA_with_collocation_multiple_experiments(SeedNum,DATAFLAG,varargin)
%
%     This file is part of CasADi.
%
%     CasADi -- A symbolic framework for dynamic optimization.
%     Copyright (C) 2010-2014 Joel Andersson, Joris Gillis, Moritz Diehl,
%                             K.U. Leuven. All rights reserved.
%     Copyright (C) 2011-2014 Greg Horn
%
%     CasADi is free software; you can redistribute it and/or
%     modify it under the terms of the GNU Lesser General Public
%     License as published by the Free Software Foundation; either
%     version 3 of the License, or (at your option) any later version.
%
%     CasADi is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%     Lesser General Public License for more details.
%
%     You should have received a copy of the GNU Lesser General Public
%     License along with CasADi; if not, write to the Free Software
%     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
%

% Adaptation of an implementation of direct collocation
% Joel Andersson, 2016
% and Lotka-Volerra problem from mintoc.de

% Written by Matthew Moye
import casadi.*
%
%% Input declarations and default setups
if ~isempty(varargin)
    probinfo=varargin{1};
else
    probinfo=struct;
end
probinfo=perform_probinfo_parameter_setups(probinfo);
varAnnealMin=probinfo.varAnnealMin;
varAnnealMax=probinfo.varAnnealMax;
Kinactivation=probinfo.Kinactivation;
mumps_mem_percent=probinfo.mumps_mem_percent;
nlp_scaling_max_gradient=probinfo.nlp_scaling_max_gradient;
mumps_pivtol=probinfo.mumps_pivtol;
mumps_pivtolmax=probinfo.mumps_pivtolmax;
UseControl=probinfo.UseControl;
Qscale=probinfo.Qscale;
SaveHess=probinfo.SaveHess;
SaveLagGrad=probinfo.SaveLagGrad;
initialparameters=probinfo.initialparameters;
compartments=probinfo.compartments;
alpha0=probinfo.alpha0;
paramsBounded=probinfo.paramsBounded;
DisplayIter=probinfo.DisplayIter;
MethodToUse=probinfo.MethodToUse;
ControlAtEnd=probinfo.ControlAtEnd;
MAXITER=probinfo.MAXITER;
TOL=probinfo.TOL;
ACCEPTABLE_TOL=probinfo.ACCEPTABLE_TOL;
hessian_approximation=probinfo.hessian_approximation;
linear_solver=probinfo.linear_solver;
GsBounded=probinfo.GsBounded;
max_hessian_perturbation=probinfo.max_hessian_perturbation;
ScaleConstraints=probinfo.ScaleConstraints;
IntegrationScheme=probinfo.IntegrationScheme;
DT=probinfo.DT;
obj_scaling_factor=probinfo.obj_scaling_factor;
defaultp=probinfo.defaultp;
Default_yinds=probinfo.Default_yinds;
Nstate=probinfo.Nstate;
parambounds=probinfo.parambounds;
modeleqns=probinfo.modeleqns;
pest_ind=probinfo.pest_ind;
correctLJPData=probinfo.correctLJPData;
SmoothControl = probinfo.SmoothControl;
TSSinds = probinfo.TSSinds;
UserXbounds=probinfo.xbounds;
UseSlack=probinfo.UseSlack;
SlackAtEnd=0;
VerboseOutput=0;
StressTest=1;
ExpandSX=1;
RunWithoutControl=probinfo.RunWithoutControl;
RampUpControl = probinfo.RampUpControl;

UseAdaptive=probinfo.UseAdaptive;
NonUniform=probinfo.NonUniform; % different then "UseAdaptive", which is intended to fit data at each of its points, even if those points are non-uniform
UseColpack=probinfo.UseColpack;
ScaleVariables=probinfo.ScaleVariables;
ScaleSlack=probinfo.ScaleSlack;
saveDir=probinfo.saveDir;
PenalizeSlope=probinfo.PenalizeSlope;
ScalingSupplied=probinfo.ScalingSupplied;
observed_variable_in_experiment=probinfo.observed_variable_in_experiment;
VariableICs = probinfo.VariableICs; % struct, same size as osberved_variable_in_experiment
forceTimeZeroStart=VariableICs(1).forceTimeZeroStart;
probinfo.forceTimeZeroStart=forceTimeZeroStart;
ObsFunLoaded=probinfo.ObsFunLoaded;
NumObsVar=1; % may get overwritten later
IappScale=probinfo.IappScale;

% needs to be supplied, else error
%hessian_approximation='limited-memory';
%% Define parameters to be estimated

%paramsBounded=0;
RandomInitialGuess=1;
weightSeed=2;
rng(SeedNum);

fprintf ('CasADi example: %s\n', mfilename ('fullpath')) ;

%% Data read
if ischar(DATAFLAG)
    dataFileName=DATAFLAG;
    NumExperiments=1;
elseif iscell(DATAFLAG)
    NumExperiments=length(DATAFLAG);
    dataFileName=DATAFLAG{1};
end
% DATA FORMAT: csvfile.
% First  column is index
% Second column is time (ms)
% Third  column is applied current (1000 units off conversion)
% Fourth column is observed membrane potential (mV)
%dataA=csvread('C:\Users\Matt\Dropbox\Matt - Casey\code\04012011\2011_04_01_0002.csv',1,0);
% can just pass filename or filename with .ext if csv file.

% However, for compatibility with Octave, csv file reading is inefficient.
% Therefore, can just use .mat files
[~,~,ext] = fileparts(dataFileName);
if isempty(ext)
    % assume is csv file
    fulldataFileName = [dataFileName,'.csv'];
    try
        dataA=csvread(fulldataFileName,1,0);
    catch
        warning([fulldataFileName, ' does not exist, trying to load .mat'])
        fulldataFileName=[dataFileName,'.mat'];
        try
            load(fulldataFileName,'data');
            dataA=data;
        catch
            error(['No file named ', dataFileName, ' exists on path with extenstion', ...
                ' .mat or .csv, or .mat file has no variable loaded named data.']);
        end
    end
else
    if strcmp(ext,'.csv')
        fulldataFileName=dataFileName;
        dataA=csvread(fulldataFileName,1,0);
    elseif strcmp(ext, '.mat')
        fulldataFileName=dataFileName;
        load(fulldataFileName,'data');
        dataA=data;
    else
        error(['No file named ', dataFileName, ' exists on path with extenstion', ...
            ' .mat or .csv'])
    end
end
% % old code
% if strcmp(dataFileName(end-2:end),'csv')
%     fulldataFileName=dataFileName;
% else
%     fulldataFileName=[dataFileName,'.csv'];
% end
% dataA=csvread(fulldataFileName,1,0);
DSF=0;
if Default_yinds  % implies probinfo.yinds=0;
    yinds=5250:5550; % fixed for all data files at the moment, unless specified explicitly
else
    if length(probinfo.yinds)==1%% just some value saying to use all the data;  sample based on numeric value
        DSF=probinfo.yinds;
        yinds=1:DSF:size(dataA,1);
    else
        yinds=probinfo.yinds;
    end
end
Iapp =IappScale*dataA(yinds,3); % N x NumVoltageObs, % for non current-clamp data, interpret as additional control
y=dataA(yinds,4);
if length(observed_variable_in_experiment(1).val)>1
    ymat=dataA(yinds,4:4+length(observed_variable_in_experiment(1).val)-1);
    NumObsVar=length(observed_variable_in_experiment(1).val);
end
Iappdata = reshape(Iapp,length(Iapp),1);
tdata =dataA(yinds,2);
dtdata=round(tdata(2)-tdata(1),8); % also assume is fixed for all data files.
if (UseAdaptive && NonUniform)
    error('These are incompatible settings. Please disable either UseAdaptive or NonUniform');
end
if  (UseAdaptive && forceTimeZeroStart)
    error('These are incompatible settings. Please disable either UseAdaptive or forceTimeZeroStart');
end
if UseAdaptive || NonUniform % also implies non uniform data
    dtdata=round(diff(tdata(1:2:end)),8); % now is a vector
end
if correctLJPData
    y = y-13;
end

%% Set up default model parameters
paramdetails.defaultp=defaultp;
paramdetails.pest_ind=pest_ind;

paramdetails.RandomInitialGuess=RandomInitialGuess;

if ~mod(size(y,1),2) % make odd (not necessary with RK4, but other schemes
    y=y(1:end-1,:);
    Iappdata=Iappdata(1:end-1,:);
    tdata=tdata(1:end-1,:);
    if length(observed_variable_in_experiment(1).val)>1
        ymat=ymat(1:end-1,:);
    end
end
y=reshape(y,length(y),1); % make column
Iappdata=reshape(Iappdata,length(Iappdata),1);
weightScales=10.^[-4:5];
weightScale=weightScales(weightSeed);
if ScaleConstraints % can mess around with this.
    SCALEFACTOR=.1;
else
    SCALEFACTOR=.1;
end
QinvStdUnscaled=SCALEFACTOR*[ones(1,compartments) 100*ones(1,Nstate-compartments)];
VariableScale=[.01*ones(1,compartments) ones(1,Nstate-compartments)]';
Qinv=weightScale*[ones(1,compartments) 10000*ones(1,Nstate-compartments)];
% Could enforce that time scale plays a role.
Rinv=[1];
if ScalingSupplied.provided
    QinvStdUnscaled=ScalingSupplied.QinvStdUnscaled;
    VariableScale=ScalingSupplied.VariableScale;
    Qinv=ScalingSupplied.Qinv;
    Rinv=ScalingSupplied.Rinv;
end

if isfield(probinfo,'dtmodel') && ~UseAdaptive
    dtmodel=probinfo.dtmodel;
else
    dtmodel=min(dtdata);
    probinfo.dtmodel=dtmodel;
end
if TSSinds
    QinvStdUnscaled(TSSinds)=QinvStdUnscaled(TSSinds)*10;
    %      Qinv(TSSinds)=Qinv(TSSinds)*10000;
    %      QinvStdUnscaled=QinvStdUnscaled/1e4;
    %      Qinv=Qinv/1e8;
end

%tdata=0:dtdata:(length(y)-1)*dtdata; % redudant

np=size(parambounds,1);
% Left in as a general reference.
%if paramsBounded
% paramboundsSpecsdotText=[ %adjusted from specs.txt
%     50,200,120 %gNa
%     5,40,20% gK
%     0.1,1,.3% gL
%     -60,-30,-40%, Vmo
%     10,100,15%, dVm
%     0.05,.25,.1%, Cm1
%     .1,1,.4%, Cm2
%     -70,-40,-60%, Vho
%     -100,-10,-15%, dVh
%     .1,5,1%, Ch1
%     1,15,7%, Ch2
%     -70,-40,-55%, Vno
%     10,100,30%, dVn
%     .1,5,1%, Cn1
%     2,12,5%, Cn2
%     ];
ClockTime=fix(clock);

if DSF
    DSF_tag = ['DSF',num2str(DSF)];
else
    DSF_tag=[];
end
if strcmp(probinfo.IntegrationScheme,'RK4')
    Method_tag = [MethodToUse,'_',probinfo.IntegrationScheme,'_dt',num2str(dtmodel),'DT',num2str(DT)];
elseif strcmp(probinfo.IntegrationScheme,'SimpsonHermite')
    Method_tag = [MethodToUse,'_',probinfo.IntegrationScheme,'_dt',num2str(dtmodel)];
end

if RampUpControl==1
    ControlNameTag='uRedo';
else
    ControlNameTag='';
end
ClockString=[num2str(ClockTime(1)),'_',num2str(ClockTime(2)),'_',num2str(ClockTime(3))];
FileName=[ 'Est',num2str(length(paramdetails.pest_ind)),...
    'Seed',num2str(SeedNum),'u',num2str(UseControl),'_',Method_tag,'_ObsFN',dataFileName,'_','NumObs',num2str(NumExperiments),DSF_tag,'_',linear_solver,'_','T',ClockString];
FileName=strrep(FileName,'.csv','dotcsv');
FileName=strrep(FileName,'.','pt');
FileName=fullfile(saveDir,FileName);  %add bit at the start.
beta=varAnnealMin;
fprintf(['Beta = ',...
    num2str(beta),'\n'])
alpha=alpha0^beta;
start = tic;

% Change this to try with more data
%numintervals=length(y)-1;
%tdata_shifted=tdata-tdata(1);
if UseAdaptive % assumes have data at fine sampling rate, but downsample elsewhere
    % but 1:1 for data and collocation knots.
    numintervals=length(y)-1;
elseif forceTimeZeroStart
    numintervals=length(0:dtmodel:tdata(end))-1;
    probinfo.forceTimeZeroStart=forceTimeZeroStart;
else
    numintervals=length(tdata(1):dtmodel:tdata(end))-1;
end
if mod(numintervals,2)
    numintervals=numintervals+1;
end
%-------------- Set Up the Problem ----------------------------- %
if beta == -1
    alpha=0;
end
[probinfo,upperbound,lowerbound,guess,tau] = setupproblem_generalmodel_struct(y,tdata,...
    Iappdata,dtmodel,paramdetails,Qinv,Rinv,parambounds,pest_ind,numintervals,...
    probinfo);
pest_start=guess(probinfo.pind);
importantDetails=[-2 0 reshape(pest_start,1,length(pest_start))];
dlmwrite([FileName,'.txt'],importantDetails,'-append',...
    'delimiter',' ');
%save([FileName,'.mat'],'guess');
%%
if isfield(probinfo,'ControlInfo') % vector: left bound, right bound, scaling
    
    power_u=probinfo.ControlInfo(5);
else
    
    power_u=2;
end

% Declare parameters
% how many leaks? default 2, must pass a parameter structure otherwise
% also, SHOULD pass reversals as well.

% Objective term
Errx=SX.sym('Errx');
%MeasurementErrx=SX.sym('MeasurementErrx');

L = Errx^2;
Lu = Errx^power_u;
% Continuous time dynamics

fobj = Function('fobj', {Errx}, {L});
fobju = Function('fobju',{Errx},{Lu});
fconj = Function('conj',{Errx}, {Errx}); % identity

% Described seperately
if ObsFunLoaded
    [f,fu,fobs] = modeleqns();
    
else
    [f,fu] = modeleqns();
end
%% Fixed step Runge-Kutta 4 integrator
%DT=.5; % fix this
% if isfield(probinfo,'DT')
% DT=probinfo.DT;
% else
% DT=.02;
% end
%DT=.05;
% M = 50; % RK4 steps per interval
M=probinfo.dtmodel/DT;
% DT = T/N/M;
% DT = probinfo.dtmodel;
DT = probinfo.dtmodel/M;
% f = Function('f', {x,p,u}, {xdot, L});
X0 = MX.sym('X0', Nstate); % system size.
U = MX.sym('U',2);
YDAT = MX.sym('YDAT',2);
%P = MX.sym('P',length(probinfo.pest_ind));
P = MX.sym('P',length(probinfo.defaultp));
IAPPX = MX.sym('IAPPX',2);
% Two time points, 1 time point, or more.
if  strcmp(probinfo.IntegrationScheme,'RK4')
    if probinfo.UseControl
        if M == 2
            X = X0;
            [k1] = fu(X, P,IAPPX{1},YDAT{1},U{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = f(X + DT * k3,P,IAPPX{1});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            [k1] = f(X, P,IAPPX{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = fu(X + DT * k3,P,IAPPX{2},YDAT{2},U{2});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            F = Function('F', {X0,P,IAPPX,YDAT,U}, {X}, char('x0','p0','Iapp','ydat','u'),char('xf'));
        elseif M ==1
            X = X0;
            [k1] = fu(X, P,IAPPX{1},YDAT{1},U{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = fu(X + DT * k3,P,IAPPX{2},YDAT{2},U{2});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            F = Function('F', {X0,P,IAPPX,YDAT,U}, {X}, char('x0','p0','Iapp','ydat','u'),char('xf'));
        else
            X = X0;
            [k1] = fu(X, P,IAPPX{1},YDAT{1},U{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = f(X + DT * k3,P,IAPPX{1});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            for j=2:M-1
                [k1] = f(X, P,IAPPX{1});
                [k2] = f(X + DT/2 * k1, P,IAPPX{1});
                [k3] = f(X + DT/2 * k2, P,IAPPX{1});
                [k4] = f(X + DT * k3,P,IAPPX{1});
                X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            end
            [k1] = f(X, P,IAPPX{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = fu(X + DT * k3,P,IAPPX{2},YDAT{2},U{2});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
            F = Function('F', {X0,P,IAPPX,YDAT,U}, {X}, char('x0','p0','Iapp','ydat','u'),char('xf'));
        end
    else
        X = X0;
        for j=1:M-1
            [k1] = f(X, P,IAPPX{1});
            [k2] = f(X + DT/2 * k1, P,IAPPX{1});
            [k3] = f(X + DT/2 * k2, P,IAPPX{1});
            [k4] = f(X + DT * k3,P,IAPPX{1});
            X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
        end
        [k1] = f(X, P,IAPPX{1});
        [k2] = f(X + DT/2 * k1, P,IAPPX{1});
        [k3] = f(X + DT/2 * k2, P,IAPPX{1});
        [k4] = f(X + DT * k3,P,IAPPX{2});
        X=X+DT/6*(k1 +2*k2 +2*k3 +k4);
        F = Function('F', {X0,P,IAPPX}, {X}, char('x0','p0','Iapp'),char('xf'));
    end
end
YDAT1 = MX.sym('YDAT1',1);
IAPPX1 = MX.sym('IAPPX1',1);
U1 = MX.sym('U1',1);

Ff= Function('Ff', {X0,P,IAPPX1}, {f(X0,P,IAPPX1)}, char('x0','p0','Iapp'),char('xf'));
Ffu = Function('Ffu', {X0,P,IAPPX1,YDAT1,U1}, {fu(X0,P,IAPPX1,YDAT1,U1)}, char('x0','p0','Iapp','ydat','u'),char('xf'));
if ObsFunLoaded
    Ffobs= Function('Ffobs', {X0,P,IAPPX1}, {fobs(X0,P,IAPPX1)}, char('x0','p0','Iapp'),char('xfobs'));
end
%Ff=f;
%Ffu=fu;
%% Initialize NLP
% Control discretization
%h = T/N;
% h used to be used as 2h, now swapped to just 2h
%h=probinfo.dtmodel;

N=probinfo.numintervals;
ObsHere=probinfo.ObsHere;
if UseAdaptive
    hvec=diff(tdata(1:2:end));
else
    hvec=2*probinfo.dtmodel*ones(N,1);
end
% Start with an empty NLP
%w={};
if ControlAtEnd && UseControl
    if UseSlack
        w=cell(N+1+N,1);
    else
        w=cell(N+1,1);
    end
else
    if UseSlack
        w = cell(N+N+1+length(probinfo.y),1);
    else
        w=cell(N+1+length(probinfo.y),1);
    end
end

w_total={};
w0 = [];
lbw = [];
ubw = [];
J = 0;
if UseControl && SmoothControl
    g=cell(N + N/2,1);
else
    g=cell(N,1);
end
g_total={};
lbg = [];
ubg = [];
wu=cell(length(probinfo.y),1);
wu_total={};
lbwu=[];
ubwu=[];
wu0=[];
dwu=cell(N/2+1,1);
gu=cell(N/2,1);
lbgu=[];
ubgu=[];
lbdwu=[];
ubdwu=[];
dwu0=[];
dwu_total={};
gu_total={};
uidx=[];
%u_t={};
u_t=cell(N+1,1);
u_t_total={};
%Fs_nou={};
Fs_nou=cell(N+1,1);
Fs_nou_total={};
%w_slack={};
w_slack=cell(N,1);
w_slack_total={};
slack_init=[];
lb_slack=[];
rb_slack=[];

w_state=cell(N+1,1);
w_state_total={};

%lbx=[-100*ones(compartments,1); zeros(Nstate-compartments,1)];
lbx=[-250*ones(compartments,1); zeros(Nstate-compartments,1)]; % standard for computational neurocience models, voltage
ubx=[100*ones(compartments,1); ones(Nstate-compartments,1)];
if ~isempty(UserXbounds)
    lbx=UserXbounds(:,1);
    ubx=UserXbounds(:,2);
end
probinfo.tdata=tdata;
if NumExperiments>1
    probinfo.yarray{1}=probinfo.y;
    probinfo.Iapparray{1}=probinfo.Iapp;
    probinfo.tdataarray{1}=probinfo.tdata;
    probinfo.obsarray{1}=probinfo.ObsHere;
end
probinfonew=probinfo;
guessnew=guess;
Ntotal=0;
alpha_1=MX.sym('alpha_1');
slackeps=.0001; % this parameter is available to shift, no conclusive limit. keep it small.
if ScaleSlack
    SlackScaleFactor=QinvStdUnscaled'.*alpha_1;
else
    SlackScaleFactor=alpha_1;
end

alpha_u = MX.sym('alpha_u');

for iv=1:NumExperiments
    %%
    ObsVarInd=observed_variable_in_experiment(iv).val;
    forceTimeZeroStart=VariableICs(iv).forceTimeZeroStart;
    probinfo.forceTimeZeroStart=forceTimeZeroStart;
    if iv>1
        %%% LOAD DATA
        dataFileName=DATAFLAG{iv};
        [~,~,ext] = fileparts(dataFileName);
        if isempty(ext)
            % assume is csv file
            fulldataFileName = [dataFileName,'.csv'];
            try
                dataA=csvread(fulldataFileName,1,0);
            catch
                warning([fulldataFileName, ' does not exist, trying to load .mat'])
                fulldataFileName=[dataFileName,'.mat'];
                try
                    load(fulldataFileName,'data');
                    dataA=data;
                catch
                    error(['No file named ', dataFileName, ' exists on path with extenstion', ...
                        ' .mat or .csv, or .mat file has no variable loaded named data.']);
                end
            end
        else
            if strcmp(ext,'.csv')
                fulldataFileName=dataFileName;
                dataA=csvread(fulldataFileName,1,0);
            elseif strcmp(ext, '.mat')
                fulldataFileName=dataFileName;
                load(fulldataFileName,'data');
                dataA=data;
            else
                error(['No file named ', dataFileName, ' exists on path with extenstion', ...
                    ' .mat or .csv'])
            end
        end
        % % old code
        %         if strcmp(dataFileName(end-2:end),'csv')
        %             fulldataFileName=dataFileName;
        %         else
        %             fulldataFileName=[dataFileName,'.csv'];
        %         end
        %         dataA=csvread(fulldataFileName,1,0); % yinds already passed
        
        if Default_yinds  % implies probinfo.yinds=0;
            yinds=5250:5550; % fixed for all data files at the moment, unless specified explicitly
        else
            if length(probinfo.yinds)==1%% just some value saying to use all the data;  sample based on numeric value
                DSF=probinfo.yinds;
                yinds=1:DSF:size(dataA,1);
            else
                yinds=probinfo.yinds;
            end
        end
        Iapp =IappScale*dataA(yinds,3); % N x NumVoltageObs
        y=dataA(yinds,4);
        NumObsVar=length(observed_variable_in_experiment(iv).val);
        if NumObsVar>1
            ymat=dataA(yinds,4:4+NumObsVar-1);
        end
        Iappdata = reshape(Iapp,length(Iapp),1);
        tdata=dataA(yinds,2);
        %  dtdata=dataA(3,2)-dataA(2,2); % also assume is fixed for all data files.
        dtdata=round(tdata(2)-tdata(1),8); % also assume is fixed for all data files.
        if UseAdaptive
            dtdata=round(diff(tdata(1:2:end)),8); % now is a vector
            dtmodel=min(dtdata);
        end
        
        if NonUniform
            dtdata=round(diff(tdata(1:2:end)),8); % now is a vector
        end
        if correctLJPData
            y = y-13;
        end
        if ~mod(size(y,1),2) % make odd (not necessary with RK4, but other schemes
            y=y(1:end-1,:);
            Iappdata=Iappdata(1:end-1,:);
            tdata=tdata(1:end-1,:);
            if length(observed_variable_in_experiment(iv).val)>1
                ymat=ymat(1:end-1,:);
            end
        end
        y=reshape(y,length(y),1);
        Iappdata=reshape(Iappdata,length(Iappdata),1);
        tdata=reshape(tdata,length(tdata),1);
        if beta == -1
            alpha=0;
        end
        %tdata_shifted=tdata-tdata(1);
        
        %tdata=0:dtdata:(length(y)-1)*dtdata;
        if UseAdaptive % assumes have data at fine sampling rate, but downsample elsewhere
            % but 1:1 for data and collocation knots.
            numintervals=length(y)-1;
        elseif forceTimeZeroStart
            numintervals=length(0:dtmodel:tdata(end))-1;
        else
            numintervals=length(tdata(1):dtmodel:tdata(end))-1;
        end
        if mod(numintervals,2)
            numintervals=numintervals+1;
        end
        [probinfonew,upperbound,lowerbound,guessnew,tau] = ...
            setupproblem_generalmodel_struct(y,tdata,Iappdata,dtmodel,paramdetails,...
            Qinv,Rinv,parambounds,pest_ind,numintervals,probinfo);
        %if ~testNoiseless
        %         if ~paramsBounded
        %             lowerbound(probinfonew.pind)=parambounds2(:,1);
        %             upperbound(probinfonew.pind)=parambounds2(:,2);
        %         end
        probinfonew.tdata=tdata;
        probinfo.yarray{iv}=probinfonew.y;
        probinfo.Iapparray{iv}=probinfonew.Iapp;
        probinfo.tdataarray{iv}=probinfonew.tdata;
        probinfo.obsarray{iv}=probinfonew.ObsHere;
        ObsHere=probinfonew.ObsHere;
        %    h=probinfonew.dtmodel;
        N=probinfonew.numintervals;
        if UseAdaptive
            hvec=diff(tdata(1:2:end));
        else
            hvec=2*probinfonew.dtmodel*ones(N,1);
        end
        if ControlAtEnd && UseControl
            if UseSlack
                w=cell(N+1+N,1);
            else
                w=cell(N+1,1);
            end
        else
            if UseSlack
                w = cell(N+N+1+length(probinfo.y),1);
            else
                w=cell(N+1+length(probinfo.y),1);
            end
        end
        
        % smooth control only works when all data observed.
        
        %  w=cell(N+1,1);
        g=cell(N,1);
        wu=cell(length(probinfonew.y),1);
        dwu=cell(N/2+1,1);
        gu=cell(N/2,1);
        u_t=cell(N+1,1);
        Fs_nou=cell(N+1,1);
        w_slack=cell(N,1);
        w_state=cell(N+1,1);
    end
    %% Formulate the NLP
    %Qinv_1=MX.sym('Qinv_1',4);
    widx=1;
    %% Reinitialize NLP
    % "Lift" initial conditions
    if ScaleVariables
        Xk =  MX.sym(['X0','_',num2str(iv)], Nstate);
        Xkuse=VariableScale.*Xk;
    else
        Xk = MX.sym(['X0','_',num2str(iv)], Nstate);
    end
    %  w = {w{:}, Xk};
    w{1}=Xk;
    widx=widx+1;
    if VariableICs(iv).known
        lbw=[lbw; VariableICs(iv).lb];
        ubw=[ubw; VariableICs(iv).ub];
    else
        lbw = [lbw; lbx];
        ubw = [ubw; ubx];
    end
    w_state{1}=Xk;
    %lbx=[-100*ones(compartments,1); zeros(Nstate-compartments,1)];
    %ubx =[100*ones(compartments,1); ones(Nstate-compartments,1)];
    if isfield(probinfo,'ControlInfo') % vector: left bound, right bound, scaling
        eta_u=probinfo.ControlInfo(3);
        lbu=probinfo.ControlInfo(1);
        ubu=probinfo.ControlInfo(2);
        %power_u=probinfo.ControlInfo(5);
    else
        eta_u=1;
        lbu=0;
        ubu=1;
        % power_u=2;
    end
    if VariableICs(iv).known
        w0 = [w0; VariableICs(iv).vals];
    else
        w0 = [w0; guessnew(probinfonew.xind(1,1:Nstate));];
    end% guess(probinfo.xind(1,2));...
    %  guess(probinfo.xind(1,3)); guess(probinfo.xind(1,4))];
    if probinfo.UseControl
        Uk = MX.sym(['U_' ,num2str(1),'_',num2str(iv)]);
        wu{1}=Uk;
        if ControlAtEnd
            %  wu={wu{:} Uk};
            %             wu{1}=Uk;
            lbwu=[lbwu; lbu];
            ubwu=[ubwu; ubu];
            wu0=[wu0; guessnew(probinfonew.uind(1,1))];
            % uidx=[udix; length(lbwu)];
        else
            w{widx}   = Uk; widx=widx+1;
            lbw = [lbw;lbu];
            ubw = [ubw;ubu];
            w0  = [w0;guessnew(probinfonew.uind(1,1))];
            uidx=[uidx; length(lbw)];
            
        end
        %  fcontrol=fobju(eta_u*Uk); % first control penalty
        fcontrol = alpha_u*fobju(Uk);
        J=J+fcontrol{:};
        if SmoothControl
            dUk = MX.sym(['dU_' num2str(1),'_',num2str(iv)]);
            % dwu={dwu{:} dUk};
            dwu{1}=dUk;
            lbdwu=[lbdwu; -1];
            ubdwu=[ubdwu; 1];
            dwu0=[dwu0; 0];
            if PenalizeSlope
                fcontrol=alpha_u*fobju(dUk);
                J=J+fcontrol{:};
            end
        end
    end
    %w = {w{:}};
    
    % make array ObsHere
    %% Formulate the NLP (again)
    %Qinv_1=MX.sym('Qinv_1',4);
    %alpha_1=MX.sym('alpha_1');
    obsCounter=1;
    obsk=2;
    if strcmp(probinfo.IntegrationScheme,'RK4')
        for k=1:N
            if k==N
                'Warning'
            end
            if DisplayIter
                if ~mod(k/N,.1)
                    %   fprintf_r('%i', t);
                    fprintf_r('Working on %d of %d, %.2f percent done', [k, N, k/N]);
                    pause(0.00000000001)
                end
            end
            % New NLP variable for the control
            if ObsHere(k)
                if probinfo.UseControl
                    Ukp1 = MX.sym(['U_' num2str(obsCounter+1),'_',num2str(iv)]);
                end
            end
            %w = {w{:}};
            % Integrate till the end of the interval
            if probinfo.UseControl && ObsHere(k)
                if ObsHere(k+1) % next point as well
                    Fk = F('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)],'ydat',[probinfonew.y(obsCounter),probinfonew.y(obsCounter+1)],'u',[Uk,Ukp1]);
                else
                    % just set that control to 0
                    Fk = F('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter)],'ydat',[probinfonew.y(obsCounter),probinfonew.y(obsCounter+1)],'u',[Uk,0]);
                end
                
            elseif probinfo.UseControl && ObsHere(k+1)
                % switching to observation
                Fk = F('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)],'ydat',[probinfonew.y(obsCounter),probinfonew.y(obsCounter+1)],'u',[0,Ukp1]);
            else
                if ObsHere(k+1)
                    Fk = F('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)]);
                else
                    Fk = F('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter)]);
                end
            end
            Xk_end = Fk.xf;
            % New NLP variable for state at end of interval
            Xkp1 = MX.sym(['X_' num2str(k+1),'_', num2str(iv)], Nstate);
            w   = {w{:} Xkp1};
            lbw = [lbw;lbx];
            ubw = [ubw;ubx];
            w0 =[w0; guessnew(probinfonew.xind(k+1,1:Nstate))];
            %     w0 =[w0; guess(probinfo.xind(k+1,1)); guess(probinfo.xind(k+1,2));...
            %         guess(probinfo.xind(k+1,3)); guess(probinfo.xind(k+1,4))];
            if probinfo.UseControl && ObsHere(k)
                w   = {w{:} Ukp1};
                lbw = [lbw;lbu];
                ubw = [ubw;ubu];
                w0  = [w0;guessnew(probinfonew.uind(obsCounter+1,:))];
                Uk=Ukp1;
            end
            % Make objective function
            if strcmp(MethodToUse,'Weak')
                fobjk_model=alpha_1.*Qinv'.*fobj((Xk_end-Xkp1));
                J=J+sum(fobjk_model);
                if ObsHere(k)
                    fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xk{ObsVarInd}-y(obsCounter));
                    J=J+fmeasure_model{:};
                end
            else
                %   if
                if ObsHere(k)
                    fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xk{ObsVarInd}-y(obsCounter));
                    J=J+fmeasure_model{:};
                end
            end
            if probinfo.UseControl && ObsHere(k) % penalize control
                % fcontrol=fobju(eta_u*Uk);\
                fcontrol = alpha_u*fobju(Uk);
                J=J+fcontrol{:}; % subsequent control penalty
            end
            if strcmp(MethodToUse,'Strong')
                if ScaleConstraints
                    g = [g, {QinvStdUnscaled'.*(Xk_end-Xk)}];
                else
                    g = [g, {Xk_end-Xk}];
                end
                lbg = [lbg; zeros(Nstate,1)];
                ubg=[ ubg; zeros(Nstate,1)];
            end
            if ObsHere(k+1)
                obsCounter=obsCounter+1;
            end
            Xk=Xkp1;
        end
        if DisplayIter
            fprintf_r('reset');
            %  pause(0.0000001)
        end
        
        
        
    elseif strcmp(probinfo.IntegrationScheme,'SimpsonHermite')
        % f = Function('f', {x,p,Iappx}, {xdot});
        %fu = Function('fu', {x,p,Iappx,ydat,u}, {xdotu});
        %Ff= Function('Ff', {X0,P,IAPPX1}, {f(X0,P,IAPPX1)}, char('x0','p0','Iapp'),char('xf'));
        %Ffu = Function('Ffu', {X0,P,IAPPX1,YDAT1,U1}, {fu(X0,P,IAPPX1,YDAT1,U1)}, char('x0','p0','Iapp','ydat','u'),char('xf'));
        if probinfo.UseControl && ObsHere(1) % THIS SHOULD BE ASSUMED TO BE THE CASE ALWAYS.
            Fk = Ffu('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter)],'ydat',[probinfonew.y(obsCounter)],'u',Uk);
            Xk_end=Fk.xf;
            
            Fk_nou_0=Ff('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter)]);
            Xk_end_nou=Fk_nou_0.xf;
            %   Fs_nou=[Fs_nou; {Xk_end{1}}];
            Fs_nou{1}=Xk_end{1};
            % penalize first one
            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xk{ObsVarInd}-y(obsCounter));
            J=J+fmeasure_model{:};
            
            % Assumes observation index at one, but presumably the
            % rest of the states would be the same so summing over
            % all shouldn't matter in principle.
            %    u_t=[u_t; {Xk_end_nou{1}-Xk_end{1}}];
            u_t{1}= Xk_end_nou{1}-Xk_end{1};
            %  if PenalizeUt
            %       f_ut = fobj(Xk_end_nou{1}-Xk_end{1});
            %      J=J+f_ut;
            %   end
            
            % Fkb1 = f('x0',Xkp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)],'ydat',[probinfonew.y(k),probinfonew.y(obsCounter+1)],'u',[Uk,Ukp1]);
        else
            Fk= Ff('x0',Xk,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter)]);
            Xk_end=Fk.xf;
            
        end
        
        for k=1:N/2 % number of intervals, but not necessarily points.
            h=hvec(k);
            % New NLP variable for the control
            if ObsHere(2*k)
                if probinfo.UseControl
                    Ukbp1 = MX.sym(['U_' num2str(obsCounter+1),'_',num2str(iv)]);
                    obsIncreaser=1;
                else
                    obsIncreaser=0;
                end
            else
                obsIncreaser=0;
            end
            if ObsHere(2*k+1)
                if probinfo.UseControl
                    Ukp1 = MX.sym(['U_' num2str(obsCounter+1+obsIncreaser),'_',num2str(iv)]);
                end
            end
            %w = {w{:}};
            % Integrate till the end of the interval
            if ScaleVariables
                Xkp1 = VariableScale.*MX.sym(['X_' num2str(k+1),'_', num2str(iv)], Nstate);
                Xkbp1 = VariableScale.*MX.sym(['X_' num2str(k+1),'b_', num2str(iv)], Nstate);
            else
                Xkp1 = MX.sym(['X_' num2str(k+1),'_', num2str(iv)], Nstate);
                Xkbp1 = MX.sym(['X_' num2str(k+1),'b_', num2str(iv)], Nstate);
            end
            %w   = {w{:} Xkbp1 Xkp1};
            %    w{2*k}=Xkbp1;
            %   w{2*k+1}=Xkp1;
            w{widx}=Xkbp1;
            w{widx+1}=Xkp1; widx=widx+2;
            
            lbw = [lbw;lbx; lbx];
            ubw = [ubw;ubx; ubx];
            w0 =[w0; guessnew(probinfonew.xind(2*k,1:Nstate)); ...
                guessnew(probinfonew.xind(2*k+1,1:Nstate))];
            
            w_state{2*k}=Xkbp1;
            w_state{2*k+1}=Xkp1;
            
            if probinfo.UseControl && ObsHere(2*k)
                Fkbp1 = Ffu('x0',Xkbp1,'p0',P,'Iapp',...
                    [probinfonew.Iapp(obsCounter+1)],...
                    'ydat',[probinfonew.y(obsCounter+1)],'u',Ukbp1);
                
                
                % Fkb1 = f('x0',Xkp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)],'ydat',[probinfonew.y(k),probinfonew.y(obsCounter+1)],'u',[Uk,Ukp1]);
            else
                Fkbp1 = Ff('x0',Xkbp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter)]);
            end
            if probinfo.UseControl && ObsHere(2*k+1)
                Fkp1 = Ffu('x0',Xkp1,'p0',P,'Iapp',...
                    [probinfonew.Iapp(obsCounter+1+obsIncreaser)],'ydat',...
                    [probinfonew.y(obsCounter+1+obsIncreaser)],'u',Ukp1);
                % Fkb1 = f('x0',Xkp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter),probinfonew.Iapp(obsCounter+1)],'ydat',[probinfonew.y(k),probinfonew.y(obsCounter+1)],'u',[Uk,Ukp1]);
            else
                Fkp1 = Ff('x0',Xkp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter+obsIncreaser)]);
            end
            Xkp1_end = Fkp1.xf;
            Xkbp1_end=Fkbp1.xf;
            % New NLP variable for state at end of interval
            %     w0 =[w0; guess(probinfo.xind(k+1,1)); guess(probinfo.xind(k+1,2));...
            %         guess(probinfo.xind(k+1,3)); guess(probinfo.xind(k+1,4))];
            if probinfo.UseControl && ObsHere(2*k)
                wu{obsk}=Ukbp1;
                obsk=obsk+1;
                if probinfo.ControlAtEnd
                    %   wu={wu{:} Ukbp1};
                    %                     wu{obsk}=Ukbp1;
                    %                     obsk=obsk+1;
                    lbwu=[lbwu; lbu];
                    ubwu=[ubwu; ubu];
                    wu0=[wu0; guessnew(probinfonew.uind(obsCounter+1,:))];
                else
                    %    w   = {w{:} Ukbp1};
                    w{widx}=Ukbp1; widx=widx+1;
                    lbw = [lbw;lbu];
                    ubw = [ubw;ubu];
                    w0  = [w0;guessnew(probinfonew.uind(obsCounter+1,:))];
                    uidx=[uidx; length(lbw)];
                    
                end
                
                % Calculate Rt
                Fkbp1_nou = Ff('x0',Xkbp1,'p0',P,'Iapp',...
                    [probinfonew.Iapp(obsCounter+1)]);
                
                Xkbp1_nou_end=Fkbp1_nou.xf;
                %  u_t=[u_t; {Xkbp1_nou_end{1}-Xkbp1_end{1}}];
                u_t{2*k-1}=Xkbp1_nou_end{1}-Xkbp1_end{1};
                %    f_ut = fobj(Xkbp1_nou_end{1}-Xkbp1_end{1});
                %  J=J+f_ut;
                Fs_nou{2*k-1}=Xkbp1_nou_end{1};
                %   Fs_nou=[Fs_nou; {Xkbp1_nou_end{1}}];
                
            end
            
            if probinfo.UseControl && ObsHere(2*k+1)
                %   wu={wu{:} Ukp1};
                wu{obsk}=Ukp1;
                obsk=obsk+1;
                if probinfo.ControlAtEnd
                    %                     %   wu={wu{:} Ukp1};
                    %                     wu{obsk}=Ukp1;
                    %                     obsk=obsk+1;
                    lbwu=[lbwu; lbu];
                    ubwu=[ubwu; ubu];
                    wu0=[wu0; guessnew(probinfonew.uind(obsCounter+1+obsIncreaser,:))];
                else
                    %w   = {w{:} Ukp1};
                    w{widx}=Ukp1; widx=widx+1;
                    lbw = [lbw;lbu];
                    ubw = [ubw;ubu];
                    w0  = [w0;guessnew(probinfonew.uind(obsCounter+1+obsIncreaser,:))];
                    uidx=[uidx; length(lbw)];
                    
                end
                % Uk=Ukp1;
                % Calculate Rt
                Fkp1_nou = Ff('x0',Xkp1,'p0',P,'Iapp',...
                    [probinfonew.Iapp(obsCounter+1+obsIncreaser)]);
                Xkp1_nou_end=Fkp1_nou.xf;
                % u_t=[u_t; {Xkp1_nou_end{1}-Xkp1_end{1}}];
                u_t{2*k}=Xkp1_nou_end{1}-Xkp1_end{1};
                %    f_ut = fobj(Xkp1_nou_end{1}-Xkp1_end{1});
                %  J=J+f_ut;
                %   Fs_nou=[Fs_nou; {Xkp1_nou_end{1}}];
                Fs_nou{2*k}=Xkp1_nou_end{1};
                
                
            end
            % Make objective function
            if strcmp(MethodToUse,'Weak')
                fobjk_model1=alpha_1.*Qinv'.*fobj((Xkbp1-.5*(Xkp1+Xk)-...
                    (h/8)*(Xk_end-Xkp1_end)));
                fobjk_model2=alpha_1.*Qinv'.*fobj(Xkp1-Xk-...
                    (h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end));
                J=J+sum(fobjk_model1)+sum(fobjk_model2);
            end
            %                 if ObsHere(k)
            %                     fmeasure_model=Rinv'.*fobj(Xk{1}-y(obsCounter+1));
            %                     J=J+fmeasure_model{:};
            %                 end
            
            if ObsHere(2*k)
                % if the user has prepared a special observation function
                if ObsFunLoaded
                    Fobskbp1 = Ffobs('x0',Xkbp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter)]);
                    Xobskbp1=Fobskbp1.xfobs;
                    % if forcing the system to start at time 0
                    if forceTimeZeroStart %actually haven't started at an observed point
                        % if multiple observed quantities
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xobskbp1{ObsVarInd(nov)}-ymat(obsCounter,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xobskbp1{ObsVarInd}-y(obsCounter));
                        end
                    else
                        % if not imposing to add time 0
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xobskbp1{ObsVarInd(nov)}-ymat(obsCounter+1,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xobskbp1{ObsVarInd}-y(obsCounter+1));
                        end
                    end
                    % Combine all measurement terms
                    for fmi=1:length(fmeasure_model)
                        J=J+fmeasure_model{fmi};
                    end
                    % if using default, index mapping of variables to output
                else
                    if forceTimeZeroStart %actually haven't started at an observed point
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xkbp1{ObsVarInd(nov)}-ymat(obsCounter,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xkbp1{ObsVarInd}-y(obsCounter));
                        end
                    else
                        if NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xkbp1{ObsVarInd(nov)}-ymat(obsCounter+1,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xkbp1{ObsVarInd}-y(obsCounter+1));
                        end
                    end
                    
                    for fmi=1:length(fmeasure_model)
                        J=J+fmeasure_model{fmi};
                    end
                end
            end
            if ObsHere(2*k+1)
                if ObsFunLoaded
                    Fobskp1 = Ffobs('x0',Xkp1,'p0',P,'Iapp',[probinfonew.Iapp(obsCounter+obsIncreaser)]);
                    Xobskp1=Fobskp1.xfobs;
                    if forceTimeZeroStart %actually haven't started at an observed point
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xobskp1{ObsVarInd(nov)}-ymat(obsCounter,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xobskp1{ObsVarInd}-y(obsCounter));
                        end
                    else
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xobskp1{ObsVarInd(nov)}-ymat(obsCounter+1,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xobskp1{ObsVarInd}-y(obsCounter+1));
                        end
                    end
                    for fmi=1:length(fmeasure_model)
                        J=J+fmeasure_model{fmi};
                    end
                else
                    if forceTimeZeroStart %actually haven't started at an observed point
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xkp1{ObsVarInd(nov)}-ymat(obsCounter+obsIncreaser,nov));
                            end
                        else
                            
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xkp1{ObsVarInd}-y(obsCounter+obsIncreaser));
                        end
                    else
                        if  NumObsVar>1
                            for nov=1:NumObsVar
                                fmeasure_model{nov}=Rinv(ObsVarInd(nov))'.*fobj(Xkp1{ObsVarInd(nov)}-ymat(obsCounter+1+obsIncreaser,nov));
                            end
                        else
                            fmeasure_model=Rinv(ObsVarInd)'.*fobj(Xkp1{ObsVarInd}-y(obsCounter+1+obsIncreaser));
                        end
                    end
                    for fmi=1:length(fmeasure_model)
                        J=J+fmeasure_model{fmi};
                    end
                end
            end
            if probinfo.UseControl && ObsHere(2*k) % penalize control
                %  fcontrol=fobju(eta_u*Ukbp1);
                fcontrol = alpha_u*fobju(Ukbp1);
                J=J+fcontrol{:}; % subsequent control penalty
            end
            if probinfo.UseControl && ObsHere(2*k+1) % penalize control
                % fcontrol=fobju(eta_u*Ukp1);
                fcontrol=alpha_u*fobju(Ukp1);
                J=J+fcontrol{:}; % subsequent control penalty
            end
            if strcmp(MethodToUse,'Strong')
                if UseSlack
                    Skp1 = MX.sym(['S_' num2str(k+1),'_', num2str(iv)], Nstate);
                    Skbp1 = MX.sym(['S_' num2str(k+1),'b_', num2str(iv)], Nstate);
                    if ScaleConstraints
                        %  g = [g, {QinvStdUnscaled'.*(Xkbp1-.5*(Xkp1+Xk)-(2*h/8)*(Xk_end-Xkp1_end) - Skbp1) }];
                        g{2*k-1}=QinvStdUnscaled'.*(Xkbp1-.5*(Xkp1+Xk)-(h/8)*(Xk_end-Xkp1_end) - Skbp1) ;
                        %    g = [g, {QinvStdUnscaled'.*(Xkp1-Xk-(2*h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) - Skp1 )}];
                        g{2*k}=QinvStdUnscaled'.*(Xkp1-Xk-(h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) - Skp1 );
                        if ScaleSlack
                            lb_slack = [lb_slack; -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx));...
                                -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                            rb_slack = [rb_slack; slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx)); ...
                                slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                        else
                            lb_slack = [lb_slack; -slackeps.*ones(size(lbx));...
                                -slackeps.*ones(size(lbx))];
                            rb_slack = [rb_slack; slackeps.*ones(size(lbx)); ...
                                slackeps.*ones(size(lbx))];
                        end
                        J = J+sum(SlackScaleFactor.*fobj(Skp1)) + sum(SlackScaleFactor.*fobj(Skbp1));
                        %       w_slack={w_slack{:} Skbp1 Skp1;};
                        w_slack{2*k-1}=Skbp1;
                        w_slack{2*k}=Skp1;
                        if ~SlackAtEnd
                            w{widx}=Skbp1;
                            w{widx+1}=Skp1;
                            widx=widx+2;
                        end
                        slack_init=[slack_init; zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate)))); ...
                            zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate))));];
                        if ~SlackAtEnd
                            w0=[w0; zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate)))); ...
                                zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate))));];
                            if ScaleSlack
                                lbw = [lbw; -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx));...
                                    -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                                ubw = [ubw; slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx)); ...
                                    slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                            else
                                lbw = [lbw; -slackeps.*ones(size(lbx));...
                                    -slackeps.*ones(size(lbx))];
                                ubw = [ubw; slackeps.*ones(size(lbx)); ...
                                    slackeps.*ones(size(lbx))];
                            end
                        end
                    else
                        %  g = [g, {QinvStdUnscaled'.*(Xkbp1-.5*(Xkp1+Xk)-(2*h/8)*(Xk_end-Xkp1_end) - Skbp1) }];
                        g{2*k-1}=(Xkbp1-.5*(Xkp1+Xk)-(h/8)*(Xk_end-Xkp1_end) - Skbp1) ;
                        %    g = [g, {QinvStdUnscaled'.*(Xkp1-Xk-(2*h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) - Skp1 )}];
                        g{2*k}=(Xkp1-Xk-(h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) - Skp1 );
                        lb_slack = [lb_slack; -slackeps*ones(size(lbx)); -slackeps*ones(size(lbx))];
                        rb_slack = [rb_slack; slackeps*ones(size(lbx)); slackeps*ones(size(lbx))];
                        J = J+sum(SlackScaleFactor.*fobj(Skp1)) + sum(SlackScaleFactor.*fobj(Skbp1));
                        %       w_slack={w_slack{:} Skbp1 Skp1;};
                        w_slack{2*k-1}=Skbp1;
                        w_slack{2*k}=Skp1;
                        if ~SlackAtEnd
                            w{widx}=Skbp1;
                            w{widx+1}=Skp1;
                            widx=widx+2;
                        end
                        slack_init=[slack_init; zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate)))); ...
                            zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate))));];
                        if ~SlackAtEnd
                            w0=[w0; zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate)))); ...
                                zeros(size(guessnew(probinfonew.xind(k+1,1:Nstate))));];
                            if ScaleSlack
                                lbw = [lbw; -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx));...
                                    -slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                                ubw = [ubw; slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx)); ...
                                    slackeps*(1./QinvStdUnscaled)'.*ones(size(lbx))];
                            else
                                lbw = [lbw; -slackeps.*ones(size(lbx));...
                                    -slackeps.*ones(size(lbx))];
                                ubw = [ubw; slackeps.*ones(size(lbx)); ...
                                    slackeps.*ones(size(lbx))];
                            end
                            
                        end
                    end
                    
                else
                    if ScaleConstraints
                        %                         g = [g, {QinvStdUnscaled'.*(Xkbp1-.5*(Xkp1+Xk)-(2*h/8)*(Xk_end-Xkp1_end))}];
                        %                         g = [g, {QinvStdUnscaled'.*(Xkp1-Xk-(2*h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end))}];
                        g{2*k-1}=QinvStdUnscaled'.*(Xkbp1-.5*(Xkp1+Xk)-(h/8)*(Xk_end-Xkp1_end)) ;
                        %    g = [g, {QinvStdUnscaled'.*(Xkp1-Xk-(2*h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) - Skp1 )}];
                        g{2*k}=QinvStdUnscaled'.*(Xkp1-Xk-(h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end) );
                    else
                        g{2*k-1} = (Xkbp1-.5*(Xkp1+Xk)-(h/8)*(Xk_end-Xkp1_end));
                        g{2*k} = (Xkp1-Xk-(h/6)*(Xkp1_end+4*Xkbp1_end+Xk_end));
                    end
                end
                lbg = [lbg; zeros(Nstate,1); zeros(Nstate,1)];
                ubg=[ ubg; zeros(Nstate,1); zeros(Nstate,1)];
            end
            
            
            if strcmp(MethodToUse,'Strong') && SmoothControl
                dUkp1 = MX.sym(['dU_' num2str(obsCounter+obsIncreaser+1),'_',num2str(iv)]);
                % dwu={dwu{:} dUkp1};
                dwu{k+1}=dUkp1;
                lbdwu=[lbdwu; -1];
                ubdwu=[ubdwu; 1];
                dwu0=[dwu0; 2*rand-1]; % random between -1 1
                %  g = [g, {Ukbp1-.5*(Ukp1+Uk)-(h/8)*(dUk-dUkp1)}];
                gu{k}=Ukbp1-.5*(Ukp1+Uk)-(h/8)*(dUk-dUkp1);
                lbgu = [lbgu; 0];
                ubgu= [ubgu; 0];
                Uk=Ukp1;
                dUk=dUkp1;
                if PenalizeSlope
                    %  fcontrol=fobju(eta_u*dUkp1);
                    fcontrol = alpha_u*(fobju(dUkp1));
                    J=J+fcontrol{:};
                end
            end
            if ObsHere(2*k)
                obsCounter=obsCounter+1;
            end
            if ObsHere(2*k+1)
                obsCounter=obsCounter+1;
            end
            obsIncreaser=0;
            Xk=Xkp1;
            Xk_end=Xkp1_end;
        end
        Ntotal=Ntotal+sum(ObsHere);
    end
    w_total={w_total{:} w{:}};
    g_total={g_total{:} g{:}};
    gu_total={gu_total{:} gu{:}};
    dwu_total={dwu_total{:} dwu{:}};
    w_slack_total={w_slack_total{:} w_slack{:}};
    Fs_nou= Fs_nou(~cellfun('isempty',Fs_nou));
    u_t = u_t(~cellfun('isempty',u_t));
    Fs_nou_total={Fs_nou_total{:} Fs_nou{:}};
    wu_total={wu_total{:} wu{:}};
    u_t_total={u_t_total{:} u_t{:}};
    w_state_total={w_state_total{:} w_state{:}};
end

if strcmp(MethodToUse,'Strong')
    normFactor=1/Ntotal;
else
    normFactor=1;
end
J=normFactor*J;
%% Fill in parameters
if probinfo.ControlAtEnd
    w_total = {w_total{:}, wu_total{:}};
    w0 = [w0; wu0];
    lbw = [lbw; lbwu];
    ubw =[ ubw; ubwu];
end
if SmoothControl
    %  w = {w{:}, dwu{:}};
    w_total={w_total{:} dwu_total{:}};
    w0 = [w0; dwu0];
    lbw = [lbw; lbdwu];
    ubw =[ ubw; ubdwu];
    g_total={g_total{:} gu_total{:}};
    lbg=[lbg; lbgu];
    ubg=[ubg; ubgu];
end

if UseSlack && SlackAtEnd
    w_total = {w_total{:}, w_slack_total{:}};
    w0 = [w0; slack_init];
    lbw = [lbw; lb_slack];
    ubw = [ubw; rb_slack];
end
w_total = {w_total{:}, P};
%w_total = { P,w_total{:},};
w0= [w0; guessnew(probinfonew.pind)];
%w0= [ guess(probinfo.pind); w0;];

lbp=lowerbound(probinfonew.pind); lbp=lbp(:);
ubp=upperbound(probinfonew.pind); ubp=ubp(:);
lbw = [lbw; lbp];
ubw = [ubw; ubp];
%lbw=[lbp; lbw];
%ubw=[ubp; ubw];
if isfield(probinfo,'FixValqt')
    FixValqt=probinfo.FixValqt;
else
    FixValqt=0;
end
if FixValqt
    % lbp(end-1)=FixValqt;
    % ubp(end-1)=FixValqt;
    % g=[g, {FixValqt-P{end-1}}];
    %     lbg=[lbg; 0];
    %     ubg=[ubg; 0];
    J=J+normFactor*fobj(P{end-1}-FixValqt);
end

% add for alpha
if strcmp(MethodToUse,'Weak') || UseSlack
    % w_total = {w_total{:}, alpha_1};
    Pconstant={alpha_1};
    % w0=[w0; alpha];
    Pconstant_val=[alpha];
    % lbw=[lbw; alpha];
    %ubw=[ubw; alpha];
else
    Pconstant={};
    Pconstant_val=[];
end

if UseControl
    Pconstant={Pconstant{:}; alpha_u};
    Pconstant_val=[Pconstant_val(:); eta_u];
end
if strcmp(MethodToUse,'Weak')
    g_total=cell(0); lbg=[]; ubg=[];
end

%% Set up functions for assessment

% set up functions so can remove space
W = vertcat(w_total{:});

if UseSlack
    w_to_slack = Function('w_to_s',{W},{vertcat(w_slack_total{:})},{'W'},{'val'});
end
if SmoothControl
    dUdt = Function('dUdt',{W},{vertcat(dwu_total{:})},{'W'},{'val'});
end

if UseControl
    u_t_f = Function('u_t_f',{W},{vertcat(u_t_total{:})},{'W'},{'val'});
    Fs_nouf = Function('Fs_nouf',{W},{vertcat(Fs_nou_total{:})},{'W'},{'val'});
    ut = Function('ut',{W},{vertcat(wu_total{:})},{'W'},{'val'});
end

state_est = Function('state_est',{W},{vertcat(w_state_total{:})},{'W'},{'val'});


%% Make space
clear Iapp Iappdata ObsHere dataA dwu_total g gu gu_total lb_slack rb_slack slack_init w_slack ...
    w_slack_total w_state w_state_total w wu_total w_total

%% Create an NLP solver
prob = struct('f', J, 'x', W, 'g', vertcat(g_total{:}),'p',vertcat(Pconstant{:}));
%prob = struct('f', J, 'x', vertcat(w{:}), 'g', []);
% solver = nlpsol('solver', 'ipopt', ...
%     prob,struct('ipopt',struct('tol',1e-6,'acceptable_tol',1e-4,...
%     'max_iter',1000,'mu_strategy','adaptive','adaptive_mu_globalization','never-monotone-mode',...
%     'bound_relax_factor',0)));%,'linear_solver','ma97')));
tic


solveropts = struct('ipopt',struct('tol',TOL,'acceptable_tol',ACCEPTABLE_TOL,...
    'max_iter',MAXITER,'mu_strategy','adaptive','adaptive_mu_globalization','never-monotone-mode',...
    'bound_relax_factor',0,'hessian_approximation',hessian_approximation,...
    'nlp_scaling_method','gradient-based','nlp_scaling_max_gradient',nlp_scaling_max_gradient,...
    'obj_scaling_factor',obj_scaling_factor,...
    'ma57_node_amalgamation',16,'ma57_block_size',100,'ma57_pivot_order',4,...
    'expect_infeasible_problem','no',...
    'linear_solver',linear_solver,'max_hessian_perturbation',max_hessian_perturbation,...
    'mumps_mem_percent',mumps_mem_percent,'mumps_pivtol',mumps_pivtol,...
    'mumps_pivtolmax',mumps_pivtolmax,'check_derivatives_for_naninf','yes',...
    'ma97_solve_blas3','no','ma97_order','metis','ma77_order','metis',...
    'ma57_pre_alloc',2,'ma57_automatic_scaling','yes',...
    'warm_start_init_point','yes',...
    'print_timing_statistics','yes','print_level',5,'max_cpu_time',15000),...
    'verbose',VerboseOutput,'expand',ExpandSX,...
    'calc_lam_x',true);
if UseColpack
    solveropts.specific_options.nlp_hess_l.helper_options.coloring_options.driver = 'colpack';
    solveropts.specific_options.nlp_hess_l.helper_options.coloring_options.order = 'NATURAL';
end
solver = nlpsol('solver', 'ipopt', ...
    prob,solveropts);%,...
toc
%  'dual_inf_tol' 0.001,...
%   compl_inf_tol 1.0e-12
% #constr_viol_tol 1.0e-8));%,'linear_solver','ma97')));


% FROM minAone
%
% # Set the max number of iterations
% max_iter 10000
% # set derivative test
% #derivative_test second-order
% # set termination criteria
% tol 1.0e-12
% #dual_inf_tol 0.001
% #compl_inf_tol 1.0e-12
% #constr_viol_tol 1.0e-8
% #acceptable_tol 1.0e-10
% #acceptable_iter
% #turn off the NLP scaling
% #nlp_scaling_method none
% #mehrotra_algorithm yes
% mu_strategy adaptive
% adaptive_mu_globalization never-monotone-mode
% linear_solver ma97
% #linear_system_scaling none
% bound_relax_factor 0
% #ma27_pivtol 1.0e-6

%
%% Solve the NLP
est=[];
probinfo.w00=w0;

sol = solver('x0', w0, 'lbx', lbw, 'ubx', ubw,...
    'lbg', lbg, 'ubg', ubg,'p',Pconstant_val);
%solver.get_function('nlp_hess_l').sparsity_out(0).to_file('H.mtx')

w_opt = full(sol.x);
solverstats=solver.stats;
LAend=(strcmp(MethodToUse,'Weak') || UseSlack);
params_est=w_opt(end-length(probinfo.defaultp)+1:end);
params_est=params_est(probinfo.pest_ind);
%params_est=w_opt(probinfo.pind);
%state_est=w_opt;
fval=full(sol.f);


if RunWithoutControl
    %Pconstant_val=alpha;
    w_opt_dm=sol.x;
    lam_g0=sol.lam_g;
    lam_x0=sol.lam_x;
    lbw(uidx)=0;
    ubw(uidx)=0;
    w_opt_dm(uidx)=0;
    sol = solver('x0', w_opt_dm, 'lbx', lbw, 'ubx', ubw,...
        'lbg', lbg, 'ubg', ubg,'p',Pconstant_val);%,...
    %   'lam_g0',lam_g0,'lam_x0',lam_x0);
    w_opt = full(sol.x);
    solverstats=solver.stats;
    LAend=(strcmp(MethodToUse,'Weak') || UseSlack);
    params_est=w_opt(end-length(probinfo.defaultp)+1:end);
    params_est=params_est(probinfo.pest_ind);
    %params_est=w_opt(probinfo.pind);
    %state_est=w_opt;
    fval=full(sol.f);
    
end


%G=vertcat(g{:});
if SaveHess && strcmp(MethodToUse,'Strong')
    stateEst=w_opt(1:end-np);
    paramEst=w_opt(end-np+1:end);
    wstate=vertcat(w_total{1:end-1});
    wparam=vertcat(w_total{end});
    H = hessian(J+dot(vertcat(g_total{:}),sol.lam_g),W);
    Jh = Function('Jh',{W,vertcat(Pconstant{:})},{H},{'w','p'},{'H'});
    ddJ=Jh('w',sol.x,'p',Pconstant_val);
    ddJ=sparse(ddJ.H);
    
    %[QH,RH]=qr(Fhes.expand());
    H.sparsity().spy_matlab('HL_sparsity.m');
    %JacProb=jacobian(J+dot(vertcat(g{:}),sol.lam_g),W);
    %Fhesinv = Function('Fhesinv', {W}, {diag(inv(H))}, {'W'}, {'H'});
    %   Fhesnew=Fhes.expand();
    
    %res = Fhes('W',[ w_opt]);
    %Jfill=Function('Jfill',{wstate},{J+dot(vertcat(g{:}),sol.lam_g)},{'W'},{'Jf'});
    %Jstates=Jfill('W',stateEst);
    %  Jstates=substitute(J+dot(vertcat(g{:}),sol.lam_g),wstate,stateEst);
    %  H=hessian(Jstates,wparam);
    %  Fhes = Function('Fhes', {wparam}, {H}, {'W'}, {'H'});
    %   resH = full(Fhes('W',paramEst));
    %res = sparse(full(res.hes));
    % figure('Color',[1 1 1])
    % spy(full(resH.H))
    % title('Hessian of J')
end
%hes = hessian(J,W);
%hes.sparsity().spy_matlab('H_sparsity.m')
%H = hessian(J+dot(vertcat(g{:}),sol.lam_g),W);
%H.sparsity().spy_matlab('HL_sparsity.m');
if SaveLagGrad && strcmp(MethodToUse,'Strong')
    JacProb=jacobian(J+dot(vertcat(g_total{:}),sol.lam_g),W);
    %Fhes = Function('Fhes', {W}, {H}, {'W'}, {'H'});
    %res = Fhes('W',[ w_opt]);
    FJ = Function('Fhes', {W,vertcat(Pconstant{:})}, {JacProb}, {'W','p'}, {'Jac'});
    res = full(FJ('W',[ w_opt],'p',Pconstant_val));
    probinfo.laggrad=full(res.Jac);
end
%res = sparse(full(res.hes));
%figure('Color',[1 1 1])
%spy(res)
%title('Hessian of J')
fprintf(['fval = ',...
    num2str(fval),' for beta =',num2str(beta),'\n'])
importantDetails=[beta fval reshape(params_est,1,length(params_est))];
dlmwrite([FileName,'.txt'],importantDetails,'-append',...
    'delimiter',' ');
% Write out R(t) to measure dependence of control
if probinfo.UseControl
    
    u_t_f_full =full(u_t_f('W',[ w_opt]));
    u_t_f_full = full(u_t_f_full.val);
    Fs_nouf_full =full(Fs_nouf('W',[ w_opt]));
    Fs_nouf_full= full(Fs_nouf_full.val);
    Rt = (Fs_nouf_full).^2 ./ (Fs_nouf_full.^2 + u_t_f_full.^2);
    probinfo.Rt=Rt;
    probinfo.Iu=u_t_f_full;
    
    ut_full =full(ut('W',[ w_opt]));
    ut_full = full(ut_full.val);
    probinfo.ut=ut_full;
end
state_est_full=full(state_est('W',[w_opt]));
state_est_full=full(state_est_full.val);
probinfo.xt=state_est_full;
probinfo.pest=params_est;


if SmoothControl
    dUdt_full=full(dUdt('W',[w_opt]));
    dUdt_full=full(dUdt_full.val);
    probinfo.dU=dUdt_full;
end
if UseSlack
    slack_full=full(w_to_slack('W',[w_opt]));
    slack_full=full(slack_full.val);
    probinfo.slacks=slack_full;
end

if RunWithoutControl
end
problemFlags=[];
if SaveHess && SaveLagGrad && strcmp(MethodToUse,'Strong')
    save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
        'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
        'sol','solverstats','res','ddJ');
elseif SaveHess && strcmp(MethodToUse,'Strong')
    save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
        'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
        'sol','solverstats','ddJ');
elseif SaveLagGrad && strcmp(MethodToUse,'Strong')
    save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
        'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
        'sol','solverstats','res');
else
    save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
        'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
        'sol','solverstats');
end

if RampUpControl
    %Pconstant_val=alpha;
    w_opt_dm=sol.x;
    lam_g0=sol.lam_g;
    lam_x0=sol.lam_x;
    %  lbw(uidx)=0;
    %   ubw(uidx)=0;
    %    w_opt_dm(uidx)=0;
    Pconstant_val(end)=eta_u*1e3;
    sol = solver('x0', w_opt_dm, 'lbx', lbw, 'ubx', ubw,...
        'lbg', lbg, 'ubg', ubg,'p',Pconstant_val,...
        'lam_g0',lam_g0,'lam_x0',lam_x0);
    w_opt = full(sol.x);
    solverstats=solver.stats;
    LAend=(strcmp(MethodToUse,'Weak') || UseSlack);
    params_est=w_opt(end-length(probinfo.defaultp)+1:end);
    params_est=params_est(probinfo.pest_ind);
    %params_est=w_opt(probinfo.pind);
    %state_est=w_opt;
    fval=full(sol.f);
    
    if probinfo.UseControl
        
        u_t_f_full =full(u_t_f('W',[ w_opt]));
        u_t_f_full = full(u_t_f_full.val);
        Fs_nouf_full =full(Fs_nouf('W',[ w_opt]));
        Fs_nouf_full= full(Fs_nouf_full.val);
        Rt = (Fs_nouf_full).^2 ./ (Fs_nouf_full.^2 + u_t_f_full.^2);
        probinfo.Rt=Rt;
        probinfo.Iu=u_t_f_full;
        
        ut_full =full(ut('W',[ w_opt]));
        ut_full = full(ut_full.val);
        probinfo.ut=ut_full;
    end
    state_est_full=full(state_est('W',[w_opt]));
    state_est_full=full(state_est_full.val);
    probinfo.xt=state_est_full;
    probinfo.pest=params_est;

    
    
    if SmoothControl
        dUdt_full=full(dUdt('W',[w_opt]));
        dUdt_full=full(dUdt_full.val);
        probinfo.dU=dUdt_full;
    end
    if UseSlack
        slack_full=full(w_to_slack('W',[w_opt]));
        slack_full=full(slack_full.val);
        probinfo.slacks=slack_full;
    end
    FileName=[ 'Est',num2str(length(paramdetails.pest_ind)),...
        'Seed',num2str(SeedNum),'u',num2str(probinfo.UseControl),ControlNameTag,'_',Method_tag,'_ObsFN',dataFileName,'_','NumObs',num2str(NumExperiments),DSF_tag,'_',linear_solver,'_','T',ClockString];
    FileName=strrep(FileName,'.csv','dotcsv');
    FileName=strrep(FileName,'.','pt');
    FileName=fullfile(saveDir,FileName);
    if SaveHess && SaveLagGrad && strcmp(MethodToUse,'Strong')
        save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
            'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
            'sol','solverstats','res','ddJ');
    elseif SaveHess && strcmp(MethodToUse,'Strong')
        save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
            'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
            'sol','solverstats','ddJ');
    elseif SaveLagGrad && strcmp(MethodToUse,'Strong')
        save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
            'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
            'sol','solverstats','res');
    else
        save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags',...
            'paramdetails','est','dataFileName','FileName','SeedNum','guess',...
            'sol','solverstats');
    end
end

if strcmp(MethodToUse,'Weak') || UseSlack
    if varAnnealMax>varAnnealMin
        for beta=varAnnealMin+1:1:varAnnealMax
            alpha=alpha0^beta;
            %w = {w{:}, alpha_1};
            % w0=w_opt;
            %  w0=[w0(1:end-1); alpha];
            %    lbw=[lbw(1:end-1); alpha];
            %    ubw=[ubw(1:end-1); alpha];
            Pconstant_val=alpha;
            w_opt_dm=sol.x;
            lam_g0=sol.lam_g;
            lam_x0=sol.lam_x;
            sol = solver('x0', w_opt_dm, 'lbx', lbw, 'ubx', ubw,...
                'lbg', lbg, 'ubg', ubg,'p',Pconstant_val,...
                'lam_g0',lam_g0,'lam_x0',lam_x0);
            w_opt = full(sol.x);
            
            solverstats=solver.stats;
            %params_est=w_opt(probinfo.pind);
            params_est=w_opt(end-np+1:end);
            fval=full(sol.f);
            fprintf(['fval = ',...
                num2str(fval),' for beta =',num2str(beta),'\n'])
            importantDetails=[beta fval reshape(params_est,1,length(params_est))];
            dlmwrite([FileName,'.txt'],importantDetails,'-append',...
                'delimiter',' ');
            
            if probinfo.UseControl
                u_t_f_full =full(u_t_f('W',[ w_opt]));
                u_t_f_full = full(u_t_f_full.val);
                Fs_nouf_full =full(Fs_nouf('W',[ w_opt]));
                Fs_nouf_full= full(Fs_nouf_full.val);
                Rt = (Fs_nouf_full).^2 ./ (Fs_nouf_full.^2 + u_t_f_full.^2);
                probinfo.Rt=Rt;
                probinfo.Iu=u_t_f_full;
                ut_full =full(ut('W',[ w_opt]));
                ut_full = full(ut_full.val);
                probinfo.ut=ut_full;
            end
            state_est_full=full(state_est('W',[w_opt]));
            state_est_full=full(state_est_full.val);
            probinfo.xt=state_est_full;
            probinfo.pest=params_est;

            if SmoothControl
                dUdt_full=full(dUdt('W',[w_opt]));
                dUdt_full=full(dUdt_full.val);
                probinfo.dU=dUdt_full;
            end
            if UseSlack
                slack_full=full(w_to_slack('W',[w_opt]));
                slack_full=full(slack_full.val);
                probinfo.slacks=slack_full;
            end
            
            parsave(FileName,w_opt,beta,fval,probinfo,problemFlags,...
                paramdetails,est,dataFileName,SeedNum,guess,solverstats);
        end
    end
end
end
function [] = parsave(FileName,w_opt,beta,fval,probinfo,problemFlags,paramdetails,est,dataFileName,SeedNum,guess,solverstats)
save([FileName,'.mat'],'w_opt','beta','fval','probinfo','problemFlags','paramdetails','est','dataFileName','FileName','SeedNum','guess','solverstats');
end
