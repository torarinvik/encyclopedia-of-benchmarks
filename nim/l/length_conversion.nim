## Convert bounded lengths between millimeters, centimeters, meters, and kilometers.
proc metersPerUnit(unit: int): float64 =
  case unit
  of 0: 0.001
  of 1: 0.01
  of 2: 1.0
  else: 1000.0

proc length_conversion*(value, fromUnitInput, toUnitInput: float64): float64 {.cdecl, exportc: "length_conversion".} =
  if value != value or value < -1_000_000.0 or value > 1_000_000.0: return -1e300
  if (fromUnitInput != 0.0 and fromUnitInput != 1.0 and fromUnitInput != 2.0 and fromUnitInput != 3.0) or
      (toUnitInput != 0.0 and toUnitInput != 1.0 and toUnitInput != 2.0 and toUnitInput != 3.0): return -1e300
  (value * metersPerUnit(int(fromUnitInput))) / metersPerUnit(int(toUnitInput))
