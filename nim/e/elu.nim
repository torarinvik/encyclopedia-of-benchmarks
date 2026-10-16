import std/math

const InvalidResult = -1.0e300
const AlphaMax = 1_000_000.0

proc elu*(x, alpha: float64): float64 {.cdecl, exportc: "elu".} =
  if x != x or alpha != alpha or x < -100.0 or x > 100.0 or alpha < -AlphaMax or alpha > AlphaMax:
    return InvalidResult
  if x < 0.0: return alpha * (exp(x) - 1.0)
  x
