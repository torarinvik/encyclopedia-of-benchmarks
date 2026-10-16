import std/math

const InvalidResult = -1.0e300

proc integrand(functionId: int64, x: float64): float64 =
  case functionId
  of 0: sqrt(x) + ln(x)
  of 1: exp(-x) * (4.0 - pow(x, 2.0))
  of 2: sqrt(2.0 * pow(x, 3.0) + 3.0)
  of 3: x + ln(2.0 * x + 1.0)
  else: InvalidResult

proc midpoint_integral_method*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "midpoint_integral_method".} =
  if values == nil or length != 4: return InvalidResult
  let functionId = values[0]
  let intervals = values[1]
  let aMilli = values[2]
  let bMilli = values[3]
  if functionId < 0 or functionId > 3 or intervals < 2 or intervals > 64 or intervals mod 2 != 0 or
      aMilli < 0 or aMilli >= bMilli or bMilli > 10000: return InvalidResult
  let a = float64(aMilli) / 1000.0
  let b = float64(bMilli) / 1000.0
  let h = (b - a) / float64(intervals)
  var xi = a
  var total = 0.0
  for _ in 0 ..< int(intervals):
    total += integrand(functionId, xi + h / 2.0)
    xi += h
  total * h
