import std/math

const InvalidResult = -1.0e300

proc softplus*(x: float64): float64 {.cdecl, exportc: "softplus".} =
  if classify(x) == fcNan or x < -100.0 or x > 100.0: return InvalidResult
  ln(1.0 + exp(x))
