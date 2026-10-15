## Hyperbolic tangent using the normalized logistic identity.
import std/math

const InvalidResult = -1.0e300

proc tanh*(x: float64): float64 {.cdecl, exportc: "tanh".} =
  if x != x or x < -10.0 or x > 10.0: return InvalidResult
  (2.0 / (1.0 + exp(-2.0 * x))) - 1.0
