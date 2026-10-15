import std/math

const InvalidResult = -1.0e300

proc softsign*(x: float64): float64 {.cdecl, exportc: "softsign".} =
  if classify(x) == fcNan or x < -1.0e100 or x > 1.0e100: return InvalidResult
  x / (1.0 + abs(x))
