import std/math

const MaxInputLength = 6

proc sample(functionId: int, x: float64): float64 =
  case functionId
  of 0: x * x * x * x
  of 1: sin(x)
  else: 1.0 / (1.0 + x * x)

proc simpson(a, b, fa, fm, fb: float64): float64 =
  (b - a) * (fa + 4.0 * fm + fb) / 6.0

proc refine(functionId: int, a, b, fa, fm, fb, whole, tolerance: float64,
            depth: int): float64 =
  let middle = (a + b) * 0.5
  let leftMiddle = (a + middle) * 0.5
  let rightMiddle = (middle + b) * 0.5
  let flm = sample(functionId, leftMiddle)
  let frm = sample(functionId, rightMiddle)
  let left = simpson(a, middle, fa, flm, fm)
  let right = simpson(middle, b, fm, frm, fb)
  let delta = left + right - whole
  if depth == 0 or abs(delta) <= 15.0 * tolerance:
    return left + right + delta / 15.0
  refine(functionId, a, middle, fa, flm, fm, left, tolerance * 0.5, depth - 1) +
    refine(functionId, middle, b, fm, frm, fb, right, tolerance * 0.5, depth - 1)

proc exactInteger(x: float64, low, high: int64): bool =
  if classify(x) in {fcNan, fcInf, fcNegInf} or x < float64(low) or x > float64(high):
    return false
  float64(int64(x)) == x

proc adaptive_simpson_quadrature*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adaptive_simpson_quadrature".} =
  if input == nil or inputLength != 5 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, 2) or not exactInteger(input[1], -2_000_000, 2_000_000) or
      not exactInteger(input[2], -2_000_000, 2_000_000) or
      not exactInteger(input[3], 7, 8) or not exactInteger(input[4], 8, 12): return -1
  let functionId = int(input[0])
  let aMicro = int64(input[1])
  let bMicro = int64(input[2])
  let exponent = int(input[3])
  let depth = int(input[4])
  if aMicro > bMicro: return -1
  if output == nil or outputCapacity < 1: return -2
  let a = float64(aMicro) / 1_000_000.0
  let b = float64(bMicro) / 1_000_000.0
  var result = 0.0
  if a != b:
    let middle = (a + b) * 0.5
    var tolerance = 1.0
    for _ in 0 ..< exponent: tolerance *= 0.1
    let fa = sample(functionId, a)
    let fm = sample(functionId, middle)
    let fb = sample(functionId, b)
    result = refine(functionId, a, b, fa, fm, fb,
                    simpson(a, b, fa, fm, fb), tolerance, depth)
  if classify(result) in {fcNan, fcInf, fcNegInf}: return -1
  output[0] = result
  return 1
