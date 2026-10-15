import std/math

const InvalidResult = -1.0e300

proc gaussian_error_linear_unit*(x: float64): float64 {.cdecl, exportc: "gaussian_error_linear_unit".} =
  if classify(x) == fcNan or x < -100.0 or x > 100.0: return InvalidResult
  x * (1.0 / (1.0 + exp(-1.702 * x)))
