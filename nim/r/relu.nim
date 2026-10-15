## Rectified linear unit over a bounded integer-valued binary64 domain.
import std/math

const InvalidResult = -1.0e300
const MaxInput = 16777216.0

proc relu*(x: float64): float64 {.cdecl, exportc: "relu".} =
  if x != x or x < -MaxInput or x > MaxInput or floor(x) != x: return InvalidResult
  if x > 0.0: return x
  0.0
