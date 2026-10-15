import std/math

const InvalidResult = -1.0e300

proc swish*(x: float64): float64 {.cdecl, exportc: "swish".} =
  if classify(x) == fcNan or x < -100.0 or x > 100.0: return InvalidResult
  let scaled = 1.0 * x
  x * (1.0 / (1.0 + exp(-scaled)))
