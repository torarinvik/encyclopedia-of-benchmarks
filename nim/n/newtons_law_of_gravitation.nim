## Solve Newton's law of gravitation for one missing parameter.
import math

const GravitationalConstant = 6.6743e-11

proc newtons_law_of_gravitation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "newtons_law_of_gravitation".} =
  if length != 4 or values == nil: return -1.0e300
  let target = values[0]
  let a = values[1]
  let b = values[2]
  let c = values[3]
  if target < 0 or target > 3 or a < 1 or a > 1000 or b < 1 or b > 1000 or c < 1 or c > 1000:
    return -1.0e300
  case target
  of 0: GravitationalConstant * (float64(a) * float64(b)) / (float64(c) * float64(c))
  of 1: float64(a) * (float64(c) * float64(c)) / (GravitationalConstant * float64(b))
  of 2: float64(a) * (float64(c) * float64(c)) / (GravitationalConstant * float64(b))
  else: sqrt((GravitationalConstant * (float64(b) * float64(c))) / float64(a))
