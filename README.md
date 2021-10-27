# DSPE-CasADi
This is an implementation of dynamical state and parameter estimation using the CasADi framework for setting up the sparse optimization problem.

The original reference for DSPE can be found here:

Abarbanel H.D.I., Creveling D.R., Farsian R., Kostuk M.
Dynamical state and parameter estimation
SIAM Journal of Applied Dynamical Systems, 8 (4) (2009), pp. 1341-1381
https://doi/10.1137/090749761

With additional material presented in :
Toth, B.A., Kostuk, M., Meliza, C.D. et al. Dynamical estimation of neuron and network properties I: variational methods. Biol Cybern 105, 217–237 (2011). https://doi.org/10.1007/s00422-011-0459-1

This software, implemented in MATLAB, builds upon CasADi, which can be installed from https://web.casadi.org/get/ . No additional toolboxes are necessary, and all solutions are found using the default installed optimizer, MUMPS. For users with particularly large/ sparse problems, the suggested software repository, which utilizes a colpack driver for coloring the hessian, can be obtained from https://github.com/casadi/binaries/releases/tag/commit-09ad006. If the specific configuration is not available, please create an issue and I will try to contract the CasaADi devs. 
