## Leaky ReLU for one vector element and a caller-supplied slope.
const InvalidResult = -1.0e300
const MaxInput = 1_000_000.0

proc leaky_relu*(x, alpha: float64): float64 {.cdecl, exportc: "leaky_relu".} =
  if x != x or alpha != alpha or x < -MaxInput or x > MaxInput or alpha < -MaxInput or alpha > MaxInput:
    return InvalidResult
  if x < 0.0: return x * alpha
  x
