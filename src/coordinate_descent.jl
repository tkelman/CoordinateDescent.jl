#
# minimize f(x) + ∑ λi⋅|xi|
#
# If warmStart is true, the descent will start from the supplied x
# otherwise it will start from 0 by setting a large value of λ which is
# decreased to the target value
function coordinateDescent!(
  x::SparseIterate,
  f::CoordinateDifferentiableFunction,
  g::Union{ProxL1, AProxL1},
  options::CDOptions=CDOptions())

  ProximalBase.numCoordinates(x) == numCoordinates(f) || throw(DimensionMismatch())
  if typeof(g) <: AProxL1
    length(g.λ) == numCoordinates(f) || throw(DimensionMismatch())
  end

  coef_iterator = options.randomize ? RandomIterator(x) : OrderedIterator(x)

  if options.warmStart
    initialize!(f, x)
    return _coordinateDescent_inner_L1!(x, f, g, coef_iterator, options)
  else
    # set x to zero and initialize
    fill!(x, zero(eltype(x)))
    initialize!(f, x)

    # find λmax
    λmax = _findLambdaMax(x, f, g)

    # find decreasing schedule for λ
    l1 = log(λmax)
    if typeof(g) <: AProxL1
      l2 = log(g.λ0)
    else
      l2 = log(g.λ)
    end
    for l in colon(l1, (l2-l1)/options.numSteps, l2)
      if typeof(g) <: AProxL1
        g1 = AProxL1(exp(l), g.λ)
      else
        g1 = ProxL1(exp(l))
      end
      _coordinateDescent_inner_L1!(x, f, g, coef_iterator, options)
    end
    return x
  end
end

# assumes that f is initialized before the call here
function _coordinateDescent_inner_L1!(
  x::SparseIterate,
  f::CoordinateDifferentiableFunction,
  g::Union{ProxL1, AProxL1},
  coef_iterator::AtomIterator,
  options::CDOptions)

  prev_converged = false
  converged = true
  for iter=1:options.maxIter

    if converged
      reset!(coef_iterator, true)
      # maxH = fullPass!(x, f, g)
    else
      reset!(coef_iterator, false)
      # maxH = nonZeroPass!(x, f, g)
    end
    maxH = _cdPass!(x, f, g, coef_iterator)
    prev_converged = converged

    # test for convergence
    converged = maxH < options.optTol

    prev_converged && converged && break
  end
  x
end

function _cdPass!(
  x::SparseIterate{T},
  f::CoordinateDifferentiableFunction,
  g::Union{ProxL1{T}, AProxL1{T}},
  coef_iterator::AtomIterator
  ) where {T<:AbstractFloat}

  maxH = zero(T)
  for ipred = coef_iterator               # coef_iterator produces original indexes
    h = descendCoordinate!(f, g, x, ipred)
    if abs(h) > maxH
      maxH = abs(h)
    end
  end
  dropzeros!(x)
  maxH
end


######

"""
Helper function that finds the smallest value of λ for which the solution is equal to zero.
"""
function _findLambdaMax(x::SparseIterate,
  f::CoordinateDifferentiableFunction,
  ::ProxL1)

  p = length(x)
  λmax = 0.
  for k=1:p
    f_g = gradient(f, x, k)
    t = abs(f_g)
    if t > λmax
      λmax = t
    end
  end
  λmax
end

"""
Helper function that finds the smallest value of λ0 for which the solution is equal to zero.
"""
function _findLambdaMax(x::SparseIterate{T},
  f::CoordinateDifferentiableFunction,
  g::AProxL1{T}) where {T<:AbstractFloat}

  p = length(x)
  λmax = zero(T)
  for k=1:p
    f_g = gradient(f, x, k)
    t = abs(f_g) / g.λ[k]
    if t > λmax
      λmax = t
    end
  end
  λmax
end
