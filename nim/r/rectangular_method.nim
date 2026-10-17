import std/math

const InvalidResult = -1.0e300

proc integrand(x: float64): float64 =
  (exp(x) / 2.0) * (cos(x) - sin(x))

proc rectangular_method*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rectangular_method".} =
  if values == nil or length != 4: return InvalidResult
  let aQuarters = values[0]
  let bQuarters = values[1]
  let intervals = values[2]
  let rule = values[3]
  if aQuarters < -64 or aQuarters >= bQuarters or bQuarters > 64 or intervals < 1 or intervals > 64: return InvalidResult
  if (bQuarters - aQuarters) mod intervals != 0 or (rule != 0 and rule != 1): return InvalidResult

  let a = float64(aQuarters) / 4.0
  let b = float64(bQuarters) / 4.0
  let step = (b - a) / float64(intervals)
  var x = a
  var total = 0.0
  for _ in 0 ..< int(intervals):
    if rule == 0:
      total += integrand(x) * step
      x += step
    else:
      x += step
      total += integrand(x) * step
  total
