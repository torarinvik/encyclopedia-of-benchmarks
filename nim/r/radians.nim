## Convert degrees to radians using the pinned expression order.
proc radians*(degree: float64): float64 {.cdecl, exportc: "radians".} =
  if not (degree >= -1_000_000.0 and degree <= 1_000_000.0): return -1.0e300
  degree / (180.0 / 3.141592653589793)
