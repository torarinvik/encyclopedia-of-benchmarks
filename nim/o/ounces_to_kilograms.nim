## Convert ounces to kilograms with the pinned coefficient and operation order.
proc ounces_to_kilograms*(ounces: float64): float64 {.cdecl, exportc: "ounces_to_kilograms".} =
  if ounces < -1000000.0 or ounces > 1000000.0: return -1e300
  (ounces * 28.3498) / 1000.0
