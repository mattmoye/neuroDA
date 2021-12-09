function probinfo = perform_probinfo_parameter_setups(probinfo)
if isfield(probinfo,'varAnnealMin')
    varAnnealMin=probinfo.varAnnealMin;
else
    varAnnealMin=30;
    probinfo.varAnnealMin=varAnnealMin;
end
if isfield(probinfo,'varAnnealMax')
    varAnnealMax=probinfo.varAnnealMax;
else
    varAnnealMax=varAnnealMin; %default will be no annealing.
    probinfo.varAnnealMax=varAnnealMax;
end
if isfield(probinfo,'Kinactivation')
    Kinactivation=probinfo.Kinactivation;
else
    Kinactivation=0; % Default
    probinfo.Kinactivation=Kinactivation;
end

if isfield(probinfo,'mumps_mem_percent')
    mumps_mem_percent=probinfo.mumps_mem_percent;
else
        mumps_mem_percent=5;
        probinfo.mumps_mem_percent=mumps_mem_percent;

end

if isfield(probinfo,'nlp_scaling_max_gradient')
    nlp_scaling_max_gradient=probinfo.nlp_scaling_max_gradient;
else
    nlp_scaling_max_gradient=100;
    probinfo.nlp_scaling_max_gradient=100;
end
if isfield(probinfo,'mumps_pivtol')
    mumps_pivtol=probinfo.mumps_pivtol;
else
    mumps_pivtol=1e-6;
    probinfo.mumps_pivtol=mumps_pivtol;
end
if isfield(probinfo,'mumps_pivtolmax')
    mumps_pivtolmax=probinfo.mumps_pivtolmax;
else
    mumps_pivtolmax=1e-1;
    probinfo.mumps_pivtolmax=mumps_pivtolmax;
end
if isfield(probinfo,'UseControl')
    UseControl=probinfo.UseControl;
else
    UseControl=0;
    probinfo.UseControl=UseControl;
end
if isfield(probinfo,'Qscale')
    Qscale=probinfo.Qscale;
else
    Qscale=1e-7;
    probinfo.Qscale=Qscale; % default
end

if isfield(probinfo,'SaveHess')
    SaveHess=probinfo.SaveHess;
else
    probinfo.SaveHess=0;
end
if isfield(probinfo,'SaveLagGrad')
    SaveLagGrad=probinfo.SaveLagGrad;
else
    probinfo.SaveLagGrad=0;
end
if ~isfield(probinfo,'initialparameters')
    probinfo.initialparameters=0; %default flag
end

if isfield(probinfo,'compartments')
    compartments=probinfo.compartments;
else
    compartments=1;
    probinfo.compartments=compartments;
end
if isfield(probinfo,'alpha0')
    alpha0=probinfo.alpha0;
else
    alpha0=1.5;
    probinfo.alpha0=alpha0; %default
end
if isfield(probinfo,'paramsBounded')
    paramsBounded=probinfo.paramsBounded;
else
    probinfo.paramsBounded=0; % default
end
if ~isfield(probinfo,'DisplayIter')
    probinfo.DisplayIter=0;
end
if isfield(probinfo,'dumbTest1')
    dumbTest1=probinfo.dumbTest1;
else
    dumbTest1=0;
    probinfo.dumbTest1=dumbTest1;
end
if isfield(probinfo,'dumbTest2')
    dumbTest2=probinfo.dumbTest2;
else
    dumbTest2=0;
    probinfo.dumbTest2=dumbTest2;
end
if isfield(probinfo,'MethodToUse') % 'Weak' or 'Strong'
    MethodToUse=probinfo.MethodToUse;
else
    MethodToUse='Weak';
    probinfo.MethodToUse=MethodToUse;
end

if ~isfield(probinfo,'ControlAtEnd')
    probinfo.ControlAtEnd=0;
end
if isfield(probinfo,'MAXITER')
    MAXITER=probinfo.MAXITER;
else
    MAXITER=500;
    probinfo.MAXITER=MAXITER;
end

if isfield(probinfo,'TOL')
    TOL=probinfo.TOL;
else
    TOL=1e-12;
    probinfo.TOL=TOL;
end

if isfield(probinfo,'ACCEPTABLE_TOL')
    ACCEPTABLE_TOL=probinfo.ACCEPTABLE_TOL;
else
    ACCEPTABLE_TOL=1e-10;
    probinfo.ACCEPTABLE_TOL=ACCEPTABLE_TOL;
end

if isfield(probinfo,'hessian_approximation') %exact or limited-memory
    hessian_approximation=probinfo.hessian_approximation;
else
    hessian_approximation='exact';
    probinfo.hessian_approximation=hessian_approximation;
end
if isfield(probinfo,'linear_solver')
    linear_solver=probinfo.linear_solver;
else
    linear_solver='mumps';
    probinfo.linear_solver=linear_solver;
end
if isfield(probinfo,'GsBounded')
    GsBounded=probinfo.GsBounded;
else
    GsBounded=1; % default
    probinfo.GsBounded=GsBounded;
end

if isfield(probinfo,'max_hessian_perturbation')
    max_hessian_perturbation=probinfo.max_hessian_perturbation;
else
    max_hessian_perturbation=10^20;
    probinfo.max_hessian_perturbation=max_hessian_perturbation;
end

if isfield(probinfo,'ScaleConstraints')
    ScaleConstraints=probinfo.ScaleConstraints;
else
    ScaleConstraints=0;
    probinfo.ScaleConstraints=ScaleConstraints;
end
if ~isfield(probinfo,'IntegrationScheme')
    
    probinfo.IntegrationScheme='RK4'; % default
end
if isfield(probinfo,'LiftedParameters')
    %add this
end

if isfield(probinfo,'DT')
    DT=probinfo.DT;
else
    DT=.02;
    probinfo.DT=DT;
end

if isfield(probinfo,'NGleak')
    NGleak=probinfo.NGleak;
else
    NGleak=2;
    probinfo.NGleak=NGleak;
end

if isfield(probinfo,'obj_scaling_factor')
    obj_scaling_factor=probinfo.obj_scaling_factor;
else
    obj_scaling_factor=1;
    probinfo.obj_scaling_factor=obj_scaling_factor;
end
if isfield(probinfo,'PassiveParameters')
    % PassiveParameters is a struct with fields "C" "Gnaleak", "Gkleak",
    % "Ena", "Ek", "Enaleak". If NGleak=1, will just expect just "Gleak",
    % "Eleak".
    probinfo.DefaultPassiveParameters=0;
else
    probinfo.DefaultPassiveParameters=1; %default
end

if isfield(probinfo,'yinds')
    if probinfo.yinds ~= 0
    probinfo.Default_yinds=0;
    else
        probinfo.Default_yinds=1;
    end
else
    probinfo.Default_yinds=1;
end

if isfield(probinfo,'correctLJPData')
    correctLJPData=probinfo.correctLJPData;
else
    probinfo.correctLJPData=0;
end
if isfield(probinfo,'SmoothControl')
    SmoothControl=probinfo.SmoothControl;
else
    probinfo.SmoothControl=0;
end

if isfield(probinfo,'TSSinds')
    TSSinds=probinfo.TSSinds;
else
    probinfo.TSSinds=0;
end
if isfield(probinfo,'ScalingStruct')
    ScalingStruct=probinfo.ScalingStruct;
    
else
    probinfo.ScalingStruct=struct('provided',0); % default
end
if isfield(probinfo,'NonUniform')
    NonUniform=probinfo.NonUniform;
    
else
    probinfo.NonUniform=0; % default
end
if isfield(probinfo,'VariableICs')
    VariableICs=probinfo.VariableICs;
else
    probinfo.VaraibleICs=struct('known',false,'forceTimeZeroStart',0);
end
if isfield(probinfo,'ObsFunLoaded')
    ObsFunLoaded=probinfo.ObsFunLoaded;
else
    probinfo.ObsFunLoaded=0;
end
