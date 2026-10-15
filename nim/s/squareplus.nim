## Squareplus activation for one element of the source vector.
import std/math

const InvalidResult = -1.0e300

proc squareplus*(x, beta: float64): float64 {.cdecl, exportc: "squareplus".} =
  if not (x >= -10000.0 and x <= 10000.0 and beta >= 0.25 and beta <= 10000.0): return InvalidResult
  (x + sqrt(x * x + beta)) / 2.0
