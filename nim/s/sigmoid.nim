import std/math

const InvalidResult = -1.0e300

proc sigmoid*(x: float64): float64 {.cdecl, exportc: "sigmoid".} =
  if classify(x) == fcNan or x < -20.0 or x > 20.0: return InvalidResult
  1.0 / (1.0 + exp(-x))
