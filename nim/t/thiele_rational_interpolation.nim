import std/math

const
  MaxN = 6
  MaxInput = 15
  GridDenominator = 18014398509481984.0
  MinNodeSeparation = 0.0625
  LowMagnitude = 0.03125000023283064365386963
  MagnitudeCap = 63.99999999976716935634613037

proc finite(value: float64): bool =
  value.classify notin {fcNan, fcInf, fcNegInf}

proc gridValue(value: float64): bool =
  if not finite(value) or value < -8.0 or value > 8.0: return false
  let scaled = value * GridDenominator
  float64(int64(scaled)) == scaled

proc guardedMagnitude(value: float64): bool =
  (value > LowMagnitude and value < MagnitudeCap) or
    (value < -LowMagnitude and value > -MagnitudeCap)

proc belowCap(value: float64): bool =
  finite(value) and value > -MagnitudeCap and value < MagnitudeCap

proc thiele_rational_interpolation*(input: ptr UncheckedArray[float64],
        inputLength: csize_t, output: ptr UncheckedArray[float64],
        outputCapacity: csize_t): int64 {.cdecl, exportc: "thiele_rational_interpolation".} =
  if input == nil or inputLength < 4 or inputLength > csize_t(MaxInput): return -1
  let nValue = input[0]
  if not gridValue(nValue) or nValue < 1.0 or nValue > float64(MaxN): return -1
  if float64(int64(nValue)) != nValue: return -1
  let n = int(nValue)
  if int(inputLength) != 2 + 2 * n: return -1

  var x: array[MaxN, float64]
  var y: array[MaxN, float64]
  var difference: array[MaxN * MaxN, float64]
  for i in 0 ..< n:
    x[i] = input[1 + 2 * i]
    y[i] = input[2 + 2 * i]
    if not gridValue(x[i]) or not gridValue(y[i]): return -1
    for j in 0 ..< i:
      if x[i] == x[j] or abs(x[i] - x[j]) < MinNodeSeparation: return -1
    difference[i] = y[i]
  let query = input[int(inputLength) - 1]
  if not gridValue(query): return -1

  for order in 1 ..< n:
    for endpoint in order ..< n:
      let denominator = difference[(order - 1) * MaxN + order - 1] - difference[(order - 1) * MaxN + endpoint]
      if not finite(denominator) or not guardedMagnitude(denominator): return -1
      let value = (x[order - 1] - x[endpoint]) / denominator
      if not belowCap(value): return -1
      difference[order * MaxN + endpoint] = value
    if not guardedMagnitude(difference[order * MaxN + order]): return -1

  var interpolated = 0.0
  var atNode = false
  for i in 0 ..< n:
    if query == x[i]:
      interpolated = y[i]
      atNode = true
      break
  if not atNode and n == 1: interpolated = y[0]
  if not atNode and n > 1:
    var tail = difference[(n - 1) * MaxN + n - 1]
    var order = n - 2
    while order > 0:
      if not guardedMagnitude(tail): return -1
      tail = difference[order * MaxN + order] + (query - x[order]) / tail
      if not belowCap(tail): return -1
      order -= 1
    if not guardedMagnitude(tail): return -1
    interpolated = y[0] + (query - x[0]) / tail
  if not belowCap(interpolated): return -1
  if output == nil or outputCapacity < 1: return -2
  output[0] = interpolated
  return 1
