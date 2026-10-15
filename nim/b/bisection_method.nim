## Find a root of one of two documented cubics by interval bisection.
const MaxCoordMilli = 100000'i64
const MaxToleranceMicro = 1000000'i64
const RootScale = 1_000_000.0
const MaxIterations = 64

func evaluate(equation: int64, x: float64): float64 =
  if equation == 0: x * x * x + 2.0 * x - 10.0
  else: x * x * x - 4.0 * x - 9.0

proc bisection_method*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bisection_method".} =
  if input == nil or length != 4: return -1
  let equation = input[0]
  let leftMilli = input[1]
  let rightMilli = input[2]
  let toleranceMicro = input[3]
  if equation < 0 or equation > 1 or leftMilli < -MaxCoordMilli or leftMilli > MaxCoordMilli or
      rightMilli < -MaxCoordMilli or rightMilli > MaxCoordMilli or leftMilli >= rightMilli or
      toleranceMicro < 1 or toleranceMicro > MaxToleranceMicro: return -1
  var left = float64(leftMilli) / 1000.0
  var right = float64(rightMilli) / 1000.0
  var fLeft = evaluate(equation, left)
  let fRight = evaluate(equation, right)
  if fLeft == 0.0: return int64(left * RootScale + 0.5)
  if fRight == 0.0: return int64(right * RootScale + 0.5)
  if (fLeft < 0.0) == (fRight < 0.0): return -2
  let tolerance = float64(toleranceMicro) / RootScale
  for _ in 0 ..< MaxIterations:
    let middle = left + (right - left) * 0.5
    let fMiddle = evaluate(equation, middle)
    if fMiddle == 0.0: return int64(middle * RootScale + 0.5)
    if (fLeft < 0.0) != (fMiddle < 0.0):
      right = middle
    else:
      left = middle
      fLeft = fMiddle
    if right - left <= tolerance:
      return int64((left + (right - left) * 0.5) * RootScale + 0.5)
  -2
