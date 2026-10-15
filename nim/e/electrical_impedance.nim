## Solve impedance, resistance, or reactance from the other two values.
import math

proc electrical_impedance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "electrical_impedance".} =
  if values == nil or length != 3: return -1.0e300
  let resistance = values[0]
  let reactance = values[1]
  let impedance = values[2]
  if resistance < 0 or resistance > 1000 or reactance < 0 or reactance > 1000 or impedance < 0 or impedance > 1000: return -1.0e300
  let zeros = (if resistance == 0: 1 else: 0) + (if reactance == 0: 1 else: 0) + (if impedance == 0: 1 else: 0)
  if zeros != 1: return -1.0e300
  let r = float64(resistance)
  let x = float64(reactance)
  let z = float64(impedance)
  let radicand = if resistance == 0: z * z - x * x
                 elif reactance == 0: z * z - r * r
                 else: r * r + x * x
  if radicand < 0.0: return -1.0e300
  sqrt(radicand)
