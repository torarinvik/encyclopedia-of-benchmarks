## Bisection square root matching the pinned C++ update and stopping rule.
proc sqrtDoubleBisect(value: float64): float64 =
  if value > 0.0 and value < 1.0:
    return 1.0 / sqrtDoubleBisect(1.0 / value)

  var low = 0.0
  var high = value
  while low <= high:
    let mid = (low + high) / 2.0
    if mid * mid > value:
      high = mid
    else:
      if value - mid * mid < 1e-12:
        return mid
      low = mid
  return -1.0

proc sqrt_double*(value: float64): float64 {.cdecl, exportc: "sqrt_double".} =
  if value == 0.0:
    return 0.0
  if value < 1.0 / 256.0 or value > 64.0:
    return -1.0
  return sqrtDoubleBisect(value)
