## Small-amplitude pendulum period: 2 * pi * sqrt(length / g).
import math

const PiValue = 3.141592653589793238462643383279502884

proc period_of_pendulum*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "period_of_pendulum".} =
  if length != 1 or values == nil: return -1.0e300
  let pendulumLength = values[0]
  if pendulumLength < 0 or pendulumLength > 1000: return -1.0e300
  let root = pow(float64(pendulumLength) / 9.80665, 0.5)
  (2.0 * PiValue) * root
