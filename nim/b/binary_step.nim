## Binary step over a bounded finite binary64 domain.
const InvalidResult = -1.0e300

proc binary_step*(x: float64): float64 {.cdecl, exportc: "binary_step".} =
  if x != x or x < -1_000_000.0 or x > 1_000_000.0: return InvalidResult
  if x >= 0.0: return 1.0
  0.0
