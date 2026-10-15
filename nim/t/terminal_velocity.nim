## Terminal velocity with standard gravity and bounded positive inputs.
import math

proc terminal_velocity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "terminal_velocity".} =
  if length != 4 or values == nil: return -1.0e300
  let mass = values[0]
  let density = values[1]
  let area = values[2]
  let dragCoefficient = values[3]
  if mass < 1 or mass > 1000 or density < 1 or density > 1000 or area < 1 or area > 1000 or dragCoefficient < 1 or dragCoefficient > 1000:
    return -1.0e300
  let numerator = (2.0 * float64(mass)) * 9.80665
  let denominator = (float64(density) * float64(area)) * float64(dragCoefficient)
  sqrt(numerator / denominator)
