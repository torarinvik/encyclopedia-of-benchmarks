## Solve one missing quantity in the ideal-plate Casimir force equation.
import std/math

const hbar = 1.054571817e-34
const speedOfLight = 3.0e8
const piValue = 3.14159265358979323846

proc casimir_effect*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "casimir_effect".} =
  if length != 3 or values == nil: return -1.0e300
  let forceUnits = values[0]
  let areaUnits = values[1]
  let distanceUnits = values[2]
  if forceUnits < 0 or forceUnits > 1000000 or areaUnits < 0 or areaUnits > 1000000 or distanceUnits < 0 or distanceUnits > 1000000: return -1.0e300
  let zeroCount = (if forceUnits == 0: 1 else: 0) + (if areaUnits == 0: 1 else: 0) + (if distanceUnits == 0: 1 else: 0)
  if zeroCount != 1: return -1.0e300
  let force = float64(forceUnits) * 1.0e-12
  let area = float64(areaUnits) * 1.0e-6
  let distance = float64(distanceUnits) * 1.0e-6
  if forceUnits == 0:
    return (hbar * speedOfLight * pow(piValue, 2.0) * area) / (240.0 * pow(distance, 4.0))
  if areaUnits == 0:
    return (240.0 * force * pow(distance, 4.0)) / (hbar * speedOfLight * pow(piValue, 2.0))
  pow((hbar * speedOfLight * pow(piValue, 2.0) * area) / (240.0 * force), 0.25)
