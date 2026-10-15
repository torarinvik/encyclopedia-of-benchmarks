const InvalidResult = -1.0e300
const MaxEndpointMilli = 100_000'i64

proc equation(x: float64): float64 = 10.0 - x * x

proc bisection_2*(input: ptr int64, length: csize_t): float64 {.cdecl, exportc: "bisection_2".} =
  if input.isNil or length != 2: return InvalidResult
  let leftMilli = input[0]
  let rightMilli = input[1]
  if leftMilli < -MaxEndpointMilli or leftMilli > MaxEndpointMilli or rightMilli < -MaxEndpointMilli or rightMilli > MaxEndpointMilli or leftMilli >= rightMilli:
    return InvalidResult
  var a = float64(leftMilli) / 1000.0
  var b = float64(rightMilli) / 1000.0
  if equation(a) * equation(b) >= 0.0: return InvalidResult
  var c = a
  while b - a >= 0.01:
    c = (a + b) / 2.0
    if equation(c) == 0.0: break
    if equation(c) * equation(a) < 0.0: b = c
    else: a = c
  c
