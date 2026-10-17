import std/math

const InvalidResult = -1.0e300

proc objective(x: float64): float64 = x * x - 3.0

proc secant*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "secant".} =
  if values == nil or length != 5: return InvalidResult
  if values[0] != 0 or values[1] < 1_000_000 or values[1] > 1_500_000 or
      values[2] < 1_600_000 or values[2] > 2_000_000 or values[1] >= values[2] or
      values[3] < 1 or values[3] > 100_000 or values[4] < 0 or values[4] > 32:
    return InvalidResult
  var x0 = float64(values[1]) / 1_000_000.0
  var x1 = float64(values[2]) / 1_000_000.0
  let tolerance = float64(values[3]) / 1_000_000_000.0
  let maxUpdates = values[4]
  for update in 0'i64 .. maxUpdates:
    let f1 = objective(x1)
    if abs(f1) <= tolerance: return x1
    if update == maxUpdates: break
    let f0 = objective(x0)
    let denominator = f1 - f0
    if denominator == 0.0: return InvalidResult
    let x2 = x1 - f1 * (x1 - x0) / denominator
    if classify(x2) in {fcNan, fcInf, fcNegInf}: return InvalidResult
    x0 = x1
    x1 = x2
  InvalidResult
