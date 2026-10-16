import std/math

const InvalidResult = -1.0e300
const PiValue = 3.14159265358979323846264338327950288

proc gaussian*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gaussian".} =
  if values == nil or length != 3: return InvalidResult
  let x = values[0]
  let mu = values[1]
  let sigma = values[2]
  if x < -100 or x > 100 or mu < -100 or mu > 100 or sigma < 1 or sigma > 100: return InvalidResult
  let difference = x - mu
  let sigmaSquared = sigma * sigma
  let normalization = 1.0 / sqrt(2.0 * PiValue * float64(sigmaSquared))
  let exponent = -float64(difference * difference) / float64(2 * sigmaSquared)
  normalization * exp(exponent)
