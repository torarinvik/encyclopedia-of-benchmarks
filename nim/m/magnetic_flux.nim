## Magnetic flux rounded to one decimal place.
import std/math

const piValue = 3.14159265358979323846

proc magnetic_flux*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "magnetic_flux".} =
  if length != 3 or values == nil: return -1.0e300
  let magneticField = values[0]
  let area = values[1]
  let angle = values[2]
  if magneticField < 0 or magneticField > 10000 or area < 0 or area > 10000 or (angle != 0 and angle != 60 and angle != 90 and angle != 120 and angle != 180): return -1.0e300
  let radians = float64(angle) * (piValue / 180.0)
  let flux = float64(magneticField) * float64(area) * cos(radians)
  round(flux * 10.0) / 10.0
