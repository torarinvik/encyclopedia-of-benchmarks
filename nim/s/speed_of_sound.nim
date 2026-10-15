## Speed of sound in a fluid: (bulk modulus / density) ** 0.5.
import math

proc speed_of_sound*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "speed_of_sound".} =
  if length != 2 or values == nil: return -1.0e300
  let density = values[0]
  let bulkModulus = values[1]
  if density < 1 or density > 1000 or bulkModulus < 1 or bulkModulus > 1000000000:
    return -1.0e300
  pow(float64(bulkModulus) / float64(density), 0.5)
