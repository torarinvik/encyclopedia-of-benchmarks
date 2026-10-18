const MaxParseableInputLength = 130

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc allowedCoordinate(value: float64): bool =
  value == 0.0 or value == 0.25 or value == 0.5 or value == 0.75

proc montecarlopi*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "montecarlopi".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, 64): return -1
  let pointCount = int(input[0])
  if inputLength != csize_t(1 + 2 * pointCount): return -1
  var inside = 0
  for point in 0 ..< pointCount:
    let x = input[1 + 2 * point]
    let y = input[2 + 2 * point]
    if not allowedCoordinate(x) or not allowedCoordinate(y): return -1
    if x * x + y * y <= 1.0: inside += 1
  let estimate = float64(inside) / float64(pointCount) * 4.0
  if classify(estimate) in {fcNan, fcInf, fcNegInf}: return -1
  if output == nil or capacity < 1: return -2
  output[0] = estimate
  1
