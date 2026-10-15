## Bragg diffraction angle, rounded to one decimal degree.
import math

const PiValue = 3.141592653589793238462643383279502884

proc roundOneEven(value: float64): float64 =
  let scaled = value * 10.0
  let lower = floor(scaled)
  let fraction = scaled - lower
  var rounded = int64(lower)
  if fraction > 0.5 or (fraction == 0.5 and rounded mod 2 != 0):
    inc rounded
  float64(rounded) / 10.0

proc bragg_angle*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "bragg_angle".} =
  if length != 3 or values == nil: return -1.0e300
  let distance = values[0]
  let order = values[1]
  let wavelength = values[2]
  if distance < 1 or distance > 1_000_000 or order < -1000 or order > 1000 or wavelength < 0 or wavelength > 1_000_000:
    return -1.0e300
  let sine = (float64(order) * float64(wavelength)) / (2.0 * float64(distance))
  if sine < -1.0 or sine > 1.0: return -1.0e300
  let degrees = arcsin(sine) * (180.0 / PiValue)
  roundOneEven(degrees)
