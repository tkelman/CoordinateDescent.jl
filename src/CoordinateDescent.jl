module CoordinateDescent

using ProximalBase
using DataStructures: binary_maxheap

export
  lasso, sqrtLasso, feasibleLasso!, scaledLasso, scaledLasso!,
  LassoPath, refitLassoPath,
  IterLassoOptions, findInitSigma,

  # CD
  CoordinateDifferentiableFunction,
  CDLeastSquaresLoss, CDWeightedLSLoss, CDQuadraticLoss, CDSqrtLassoLoss,
  CDOptions,
  coordinateDescent, coordinateDescent!,

  # var coef
  GaussianKernel, SmoothingKernel, evaluate,
  locpoly, locpolyl1

include("utils.jl")
include("atom_iterator.jl")
include("cd_differentiable_function.jl")
include("coordinate_descent.jl")
include("lasso.jl")
include("varying_coefficient_lasso.jl")

end
