import std/math

const Pi = 3.14159265358979323846

proc isFiniteValue(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc roundedSix(value: float64): float64 =
  let magnitude = floor(abs(value) * 1_000_000.0 + 0.5) / 1_000_000.0
  if value < 0.0: -magnitude else: magnitude

proc integerPower(value: float64, exponent: int): float64 =
  var result = 1.0
  for _ in 0 ..< exponent: result *= value
  result

proc factorialDouble(n: int): float64 =
  var result = 1.0
  for factor in 2 .. n: result *= float64(factor)
  result

proc trigSeries(inputValue, tolerance: float64, kind: int): float64 =
  var value = inputValue
  let period = 2.0 * Pi
  while value >= period: value -= period
  while value <= -period: value += period
  var result = 0.0
  var previous = 1.0
  var step = 0
  while abs(previous - result) > tolerance:
    previous = result
    let power = 2 * step + kind
    let term = integerPower(value, power) / factorialDouble(power)
    if step mod 2 == 0: result += term else: result -= term
    inc step
  roundedSix(result)

proc trig_functions*(values: ptr UncheckedArray[float64], length: csize_t,
                     output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "trig_functions".} =
  if values == nil or length != 3: return -1
  let selectorValue = values[0]
  var x = values[1]
  let tolerance = values[2]
  if not isFiniteValue(selectorValue) or selectorValue < 0.0 or selectorValue > 7.0 or selectorValue != floor(selectorValue): return -1
  if not isFiniteValue(tolerance) or tolerance < 1e-9 or tolerance > 1e-2: return -1
  if isFiniteValue(x) and (x < -10000.0 or x > 10000.0): return -1
  if output == nil or capacity < 1: return -2
  if not isFiniteValue(x):
    output[0] = NaN
    return 1

  let selector = int(selectorValue)
  if selector in {2, 3, 6, 7}: x = x * Pi / 180.0
  var result = 0.0
  if selector == 0 or selector == 2:
    result = trigSeries(x, tolerance, 1)
  elif selector == 1 or selector == 3:
    result = trigSeries(x, tolerance, 0)
  elif selector == 4 or selector == 6:
    let denominator = trigSeries(x, tolerance, 0)
    result = if denominator == 0.0: NaN else: trigSeries(x, tolerance, 1) / denominator
  else:
    let denominator = trigSeries(x, tolerance, 1)
    result = if denominator == 0.0: NaN else: trigSeries(x, tolerance, 0) / denominator
  output[0] = result
  1
