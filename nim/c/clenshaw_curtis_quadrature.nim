import std/math

const MaxParseableInputLength = 19
const PiPinned = 3.14159265358979323846264338327950288

proc exactInteger(value: float64, low, high: int): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int(value)) == value

proc compute(n: int, samples: ptr UncheckedArray[float64]): float64 =
  var result = 0.0
  for k in 0 .. n:
    var inner = 0.0
    for j in 1 .. n div 2:
      let bj = if j == n div 2: 1.0 else: 2.0
      let denominator = float64(4 * j * j - 1)
      let angle = (((2.0 * float64(j)) * float64(k)) * PiPinned) / float64(n)
      let term = (bj / denominator) * cos(angle)
      inner += term
    let gk = if k == 0 or k == n: 1.0 else: 2.0
    let weight = (gk / float64(n)) * (1.0 - inner)
    result += weight * samples[k + 1]
  result

proc clenshaw_curtis_quadrature*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "clenshaw_curtis_quadrature".} =
  if input == nil or inputLength < 4 or inputLength > MaxParseableInputLength.csize_t: return -1
  if not exactInteger(input[0], 2, 16): return -1
  let n = int(input[0])
  if n mod 2 != 0 or inputLength != (n + 2).csize_t: return -1
  for i in 1 ..< inputLength.int:
    if classify(input[i]) in {fcNan, fcInf, fcNegInf} or abs(input[i]) > 1000.0: return -1
  if output == nil or outputCapacity < 1: return -2
  let value = compute(n, input)
  if classify(value) in {fcNan, fcInf, fcNegInf}: return -1
  output[0] = value
  1
