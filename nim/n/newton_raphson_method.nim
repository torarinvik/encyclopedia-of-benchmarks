import std/math

const InvalidResult = -1.0e300

proc equation(x: float64): float64 = pow(x, 3.0) - (4.0 * x) - 9.0
proc derivative(x: float64): float64 = 3.0 * pow(x, 2.0) - 4.0

proc newton_raphson_method*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "newton_raphson_method".} =
  if values == nil or length != 2: return InvalidResult
  let initialMilli = values[0]
  let iterationLimit = values[1]
  if initialMilli < 2000 or initialMilli > 4000 or iterationLimit < 1 or iterationLimit > 32:
    return InvalidResult
  var c = float64(initialMilli) / 1000.0
  var z = c
  for _ in 0 ..< int(iterationLimit):
    let m = equation(c)
    let n = derivative(c)
    z = c - (m / n)
    c = z
    if abs(m) < 1e-10: break
  z
