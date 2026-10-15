import std/math

const InvalidResult = -1.0e300

proc toF32(value: float64): float32 = float32(value)
proc powF32(base, exponent: float32): float32 = toF32(pow(float64(base), float64(exponent)))
proc logF32(value: float32): float32 = toF32(ln(float64(value)))

proc geometricCdf(p: float32, k: int64): float32 =
  1.0'f32 - powF32(1.0'f32 - p, float32(k))

## Deterministic operations of the source's first-success geometric distribution.
proc geometric_dist*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "geometric_dist".} =
  if values == nil or length < 2: return InvalidResult
  let operation = values[0]
  let pCode = values[1]
  if pCode < 0 or pCode > 2: return InvalidResult
  let probabilities = [0.25'f32, 0.5'f32, 0.75'f32]
  let p = probabilities[int(pCode)]
  if operation >= 0 and operation <= 2:
    if length != 2: return InvalidResult
    if operation == 0: return float64(1.0'f32 / p)
    let variance = (1.0'f32 - p) / (p * p)
    if operation == 1: return float64(variance)
    return float64(toF32(sqrt(float64(variance))))
  if operation == 3 or operation == 4:
    if length != 3: return InvalidResult
    let k = values[2]
    if operation == 3 and (k < 1 or k > 16): return InvalidResult
    if operation == 4 and (k < 0 or k > 16): return InvalidResult
    if operation == 3:
      return float64(powF32(1.0'f32 - p, float32(k - 1)) * p)
    return float64(geometricCdf(p, k))
  if operation == 5:
    if length != 3 or values[2] < 0 or values[2] > 2: return InvalidResult
    let cdfValues = [0.25'f32, 0.5'f32, 0.75'f32]
    let cdf = cdfValues[int(values[2])]
    return float64(logF32(1.0'f32 - cdf) / logF32(1.0'f32 - p))
  if operation == 6:
    if length != 4: return InvalidResult
    let minimum = values[2]
    let maximum = values[3]
    if minimum < 1 or maximum < minimum or maximum > 16: return InvalidResult
    return float64(geometricCdf(p, maximum) - geometricCdf(p, minimum - 1))
  InvalidResult
