function [probinfo,upperbound,lowerbound,guess, tau] = setupproblem_generalmodel_struct(obsdata,tdata,Iappdata,dtmodel,paramdetails,Qinv,Rinv,parambounds,pest_ind,numintervals,probinfo,varargin)
% Copyright 2011-2014 Matthew J. Weinstein and Anil V. Rao
% Distributed under the GNU General Public License version 3.0
%
% Altered for use with 4D-Var by Matthew J. Moye.
% vdata are voltage data
% tdata are time data
% Iapp are applied current data
% np are number of parameters
% parambounds are np x 2 for lb,ub
%
if isfield(probinfo,'compartments')
    compartments=probinfo.compartments;
else
    compartments=1;
end
RandomInitialGuess=paramdetails.RandomInitialGuess;
defaultp=paramdetails.defaultp;
n = length(Qinv); % v m h n (q)
if probinfo.UseControl
    m=1;
else
    m = 0 ; % no control (for now)
end
% m = 1;
nobs=1; % just voltage

numintervalsdata=length(tdata)-1;
np = length(defaultp);
if probinfo.UseAdaptive
    dtdata=round(min(diff(tdata(1:2:end))),8);
else
dtdata=round(min(diff(tdata)),8); % assumes uniform
end

%assert(mod(numintervals/numintervalsdata,1)==0, '%s: Data and model should coincide with their windows');
StepsPerObs=dtdata/dtmodel;
assert(mod(round(StepsPerObs,1),1)==0, '%s: Data and model should have integer time difference ratio');

K = numintervals; % number of intervals (obviously)
%N = numintervals*2+1; % number of data points
N = numintervals+1; % "effective" dt is dt*2, but estimated every dt.

% Here we need to prescribe the intervals for the model. The model will be
% discretized such that points will be coincident with the points of the
% data, but are free to be of better resolution.

probinfo.numintervals = numintervals;
probinfo.n = n;
probinfo.m = m;

probinfo.k  = 1:2:N-1;
probinfo.kbp1 = probinfo.k+1;
probinfo.kp1    = probinfo.k+2;

probinfo.xind  = reshape(1:n*N,N,n);
if probinfo.NonUniform
    if probinfo.forceTimeZeroStart
    tmodel=(0:dtmodel:N*dtmodel);
    tmodel=tmodel';
    [vals, ia,ib]= intersect(round(tdata,3),round(tmodel,3));
    probinfo.obsind = ib';
    else
            tmodel=round(tdata(1),3):dtmodel:(round(tdata(1),3)+N*dtmodel);
    tmodel=tmodel';
    [vals, ia,ib]= intersect(round(tdata,3),round(tmodel,3));
    probinfo.obsind = ib';
    end
else
probinfo.obsind = [1:StepsPerObs:N]';
end

if strcmp(probinfo.IntegrationScheme,'RK4') && probinfo.UseAdaptive && tdata(1)~=0
    StepsPerObs=1;
    N=N+1;
    probinfo.obsind = [2:StepsPerObs:N]';
    probinfo.xind  = reshape(1:n*N,N,n);
probinfo.numintervals = numintervals+1;
end
temparray=zeros(N,1);
temparray(probinfo.obsind)=1;
probinfo.ObsHere=temparray;
Ndata=length(probinfo.obsind);
if probinfo.UseControl
    probinfo.uind  = reshape(n*N+1:n*N+m*Ndata,Ndata,m);
    probinfo.pind=probinfo.uind(end)+1:probinfo.uind(end)+np;
else
    probinfo.pind = probinfo.xind(end)+1:probinfo.xind(end)+np;
end
%probinfo.tfind = probinfo.uind(end)+1;
%probinfo.pind = probinfo.xind(end)+1:probinfo.xind(end)+np;
probinfo.y=obsdata;
probinfo.Iapp=Iappdata;
probinfo.dtmodel=dtmodel;
probinfo.pest_ind=pest_ind;
Qinv=reshape(Qinv,1,n);
Qinv=repmat(Qinv,2*length(probinfo.kbp1),1);
probinfo.Qinv=Qinv(:);
% Rinv=reshape(Rinv,1,nobs);
% Rinv=repmat(Rinv,length(probinfo.y),1);
% probinfo.Rinv=Rinv(:);

% Set Bounds;
%numvars = probinfo.tfind;
numvars = probinfo.pind(end);
upperbound = zeros(numvars,1);
lowerbound = zeros(numvars,1);
% State
upperbound(probinfo.xind(:,1:compartments) )= 100;
upperbound(probinfo.xind(:,compartments+1:n)) = 1;
lowerbound(probinfo.xind(:,1:compartments)) = -100;
lowerbound(probinfo.xind(:,compartments+1:n))=0;

% Control
if probinfo.UseControl
    if isfield(probinfo,'ControlInfo') % vector: left bound, right bound, scaling
        eta_u=probinfo.ControlInfo(3);
        lbu=probinfo.ControlInfo(1);
        ubu=probinfo.ControlInfo(2);
        if length(probinfo.ControlInfo)>3
            FixInitialU=1;
            initialu=probinfo.ControlInfo(4);
        else
            lbu=0;
            ubu=1;
            FixInitialU=0;
        end
        upperbound(probinfo.uind)=lbu;
        lowerbound(probinfo.uind)=ubu;
    else
    end
end
upperbound(probinfo.pind) = parambounds(:,2);
lowerbound(probinfo.pind) = parambounds(:,1);
tau = linspace(0,1,N);
% Set Guesses
guess = zeros(numvars,1);
if isempty(varargin) % no varargin
    
    guess(probinfo.xind) = lowerbound(probinfo.xind)+...
        (upperbound(probinfo.xind)-lowerbound(probinfo.xind))...
        .*rand(size(upperbound(probinfo.xind)));
    guess(probinfo.obsind)=probinfo.y; % fill in with observations.
    
    guess(probinfo.pind)=defaultp;
    if RandomInitialGuess
        guess(probinfo.pind(pest_ind))=  lowerbound(probinfo.pind(pest_ind))+...
            (upperbound(probinfo.pind(pest_ind))-lowerbound(probinfo.pind(pest_ind)))...
            .*rand(size(upperbound(probinfo.pind(pest_ind))));
    else
        guess(probinfo.pind) = defaultp;
    end
    % swapped order so that parameter initial guesses should be same if
    % using control or not.
    if probinfo.UseControl
        if ~FixInitialU
            guess(probinfo.uind)=lowerbound(probinfo.uind)+...
                (upperbound(probinfo.uind)-lowerbound(probinfo.uind))...
                .*rand(size(upperbound(probinfo.uind)));
        else
            guess(probinfo.uind)=initialu.*ones(size(guess(probinfo.uind)));
        end
    end
%     
%     if problemFlags.UseTrueStates.flag
%         guess(probinfo.xind(2:n,:))=problemFlags.UseTrueStates.yorig(2:n,:);
%     end
%     
%     if problemFlags.UseTrueParams
%         guess(probinfo.pind)=defaultp(probinfo.pest_ind);
%     end
    
else
    Xold   = varargin{1};
    % Uold   = varargin{2};
    %tfold  = varargin{3};
    tauold = varargin{2};
    pold   = varargin{3};
    if probinfo.UseControl
        uold = varargin{4};
        guess(probinfo.uind)=uold;
    end
    if ~(length(tauold) == length(tau))
        guess(probinfo.xind) = interp1(tauold(:),Xold,tau(:));
    else
        guess(probinfo.xind)=Xold;
    end
    guess(probinfo.pind) = pold;
end

% HalfConstraints=problemFlags.HalfConstraints;
% if HalfConstraints
%     probinfo.Qinv=probinfo.Qinv(1:2:end); %
% end

