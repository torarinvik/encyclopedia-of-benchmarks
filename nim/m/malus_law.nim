## Malus's law: I0 * cos(radians(angle))^2.
import math

const PiValue = 3.141592653589793238462643383279502884

proc malus_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "malus_law".} =
  if length != 2 or values == nil: return -1.0e300
  let initialIntensity = values[0]
  let angle = values[1]
  if initialIntensity < 0 or initialIntensity > 1000 or angle < 0 or angle > 360:
    return -1.0e300
  let radians = (float64(angle) * PiValue) / 180.0
  let cosine = cos(radians)
  float64(initialIntensity) * (cosine * cosine)
