## Mish activation for one element of the source vector.
import std/math

const InvalidResult = -1.0e300

proc mish*(x: float64): float64 {.cdecl, exportc: "mish".} =
  if not (x >= -20.0 and x <= 20.0): return InvalidResult
  let softplus = ln(1.0 + exp(x))
  x * tanh(softplus)
