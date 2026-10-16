import std/math

const InvalidResult = -1.0e300

proc sigmoid_without_inbuilt*(x, slope: float64): float64 {.cdecl, exportc: "sigmoid_without_inbuilt".} =
  if x != x or slope != slope or x < -10.0 or x > 10.0 or slope < -10.0 or slope > 10.0:
    return InvalidResult
  1.0 / (1.0 + exp(-slope * x))

