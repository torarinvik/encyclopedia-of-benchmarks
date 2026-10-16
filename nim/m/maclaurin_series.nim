import std/math

const InvalidResult = -1.0e300
const PiValue = 3.14159265358979323846264338327950288

proc factorial(n: int64): float64 =
  result = 1.0
  for i in 2'i64 .. n: result *= float64(i)

proc maclaurin_series*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "maclaurin_series".} =
  if values == nil or length != 3: return InvalidResult
  let mode = values[0]
  let thetaInput = values[1]
  let accuracy = values[2]
  if (mode != 0 and mode != 1) or thetaInput < -10 or thetaInput > 10 or accuracy < 1 or accuracy > 30: return InvalidResult
  var theta = float64(thetaInput)
  let div = floor(theta / (2.0 * PiValue))
  theta = theta - 2.0 * div * PiValue
  var total = 0.0
  for r in 0'i64 ..< accuracy:
    let exponent = if mode == 0: 2 * r + 1 else: 2 * r
    let sign = if r mod 2 == 0: 1.0 else: -1.0
    total += sign * pow(theta, float64(exponent)) / factorial(exponent)
  total
