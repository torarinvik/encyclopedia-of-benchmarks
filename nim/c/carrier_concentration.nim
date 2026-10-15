## Solve the missing semiconductor carrier concentration.
import std/math

proc carrier_concentration*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "carrier_concentration".} =
  if length != 3 or values == nil: return -1.0e300
  let electron_conc = values[0]
  let hole_conc = values[1]
  let intrinsic_conc = values[2]
  if electron_conc < 0 or electron_conc > 1000000 or hole_conc < 0 or hole_conc > 1000000 or intrinsic_conc < 0 or intrinsic_conc > 1000000:
    return -1.0e300
  let zero_count = (if electron_conc == 0: 1 else: 0) + (if hole_conc == 0: 1 else: 0) + (if intrinsic_conc == 0: 1 else: 0)
  if zero_count != 1: return -1.0e300
  if electron_conc == 0: return float64(intrinsic_conc * intrinsic_conc) / float64(hole_conc)
  if hole_conc == 0: return float64(intrinsic_conc * intrinsic_conc) / float64(electron_conc)
  pow(float64(electron_conc * hole_conc), 0.5)
