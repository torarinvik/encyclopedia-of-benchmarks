import std/math

const InvalidResult = -1.0e300
const AlphaMax = 1_000_000.0

proc exponential_linear_unit*(x, alpha: float64): float64 {.cdecl, exportc: "exponential_linear_unit".} =
  if x != x or alpha != alpha or x < -100.0 or x > 100.0 or alpha < -AlphaMax or alpha > AlphaMax:
    return InvalidResult
  if x < 0.0: return x * (alpha * (exp(x) - 1.0))
  x
