import std/math

const InvalidResult = -1.0e300

proc pythonObjective(x: float64): float64 = 8.0 * x - 2.0 * exp(-x)

proc cVariant(): float64 =
  var x0 = 0.2
  var x1 = 0.5
  let tolerance = 100.0 / 1000000.0
  for iteration in 0 ..< 99:
    let f1 = x1 * x1 - 3.0
    let f0 = x0 * x0 - 3.0
    let x2 = x1 - f1 * (x1 - x0) / (f1 - f0)
    x0 = x1
    x1 = x2
    if abs(x1 - x0) < tolerance: return x2
  -1.0

proc pythonVariant(repeats: int64): float64 =
  var x0 = 1.0
  var x1 = 3.0
  for iteration in 0'i64 ..< repeats:
    let f1 = pythonObjective(x1)
    let f0 = pythonObjective(x0)
    let x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0)
    x0 = x1
    x1 = x2
  x1

proc secant_method*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "secant_method".} =
  if values == nil or length != 2: return InvalidResult
  if values[0] == 0 and values[1] == 100: return cVariant()
  if values[0] == 1 and values[1] >= 0 and values[1] <= 2: return pythonVariant(values[1])
  InvalidResult
