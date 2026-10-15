## RMS molecular speed: (3 * R * temperature / molar_mass) ** 0.5.
import math

proc rms_speed_of_molecule*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rms_speed_of_molecule".} =
  if length != 2 or values == nil: return -1.0e300
  let temperature = values[0]
  let molarMass = values[1]
  if temperature < 0 or temperature > 1000 or molarMass < 1 or molarMass > 1000:
    return -1.0e300
  let numerator = (3.0 * 8.3144598) * float64(temperature)
  pow(numerator / float64(molarMass), 0.5)
