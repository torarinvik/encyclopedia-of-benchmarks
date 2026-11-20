import std/math

const MaxParseableInputLength = 3
const PiPinned = 3.14159265358979323846264338327950288

proc exactInteger(value: float64, low, high: int): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int(value)) == value

proc integrate(functionId, p: int): float64 =
  let h = 1.0 / float64(1 shl p)
  let halfPi = PiPinned / 2.0
  let limit = 3 * (1 shl p)
  var total = 0.0
  for j in -limit .. limit:
    let t = float64(j) * h
    let expT = exp(t)
    let expMinusT = exp(-t)
    let sinhT = (expT - expMinusT) * 0.5
    let coshT = (expT + expMinusT) * 0.5
    let u = halfPi * sinhT
    let absU = if u < 0.0: -u else: u
    let q = exp(-2.0 * absU)
    let onePlusQ = 1.0 + q
    let sechSquared = (4.0 * q) / (onePlusQ * onePlusQ)
    let magnitudeX = (1.0 - q) / onePlusQ
    let x = if u >= 0.0: magnitudeX else: -magnitudeX
    let jacobian = (halfPi * coshT) * sechSquared
    var sample: float64
    if functionId == 0: sample = 1.0
    elif functionId == 1: sample = x * x
    elif functionId == 2: sample = 1.0 / sqrt(sechSquared)
    elif u >= 0.0: sample = 1.0 / sqrt((2.0 * q) / onePlusQ)
    else: sample = 1.0 / sqrt(2.0 / onePlusQ)
    let transformed = sample * jacobian
    total += h * transformed
  total

proc tanh_sinh_double_exponential_quadrature*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tanh_sinh_double_exponential_quadrature".} =
  if input == nil or inputLength < 2 or inputLength > MaxParseableInputLength.csize_t: return -1
  if inputLength != 2 or not exactInteger(input[0], 0, 3) or not exactInteger(input[1], 2, 4): return -1
  if output == nil or outputCapacity < 1: return -2
  let value = integrate(int(input[0]), int(input[1]))
  if classify(value) in {fcNan, fcInf, fcNegInf}: return -1
  output[0] = value
  1
