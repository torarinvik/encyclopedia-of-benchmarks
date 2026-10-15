## Mass-energy equivalence, with an operation selector for both source APIs.
const SpeedOfLight = 299792458.0
const SpeedOfLightSquared = SpeedOfLight * SpeedOfLight

proc mass_energy_equivalence*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mass_energy_equivalence".} =
  if length != 2 or values == nil: return -1.0e300
  let operation = values[0]
  let value = values[1]
  if (operation != 0 and operation != 1) or value < 0 or value > 1_000_000_000'i64:
    return -1.0e300
  if operation == 0:
    return float64(value) * SpeedOfLightSquared
  float64(value) / SpeedOfLightSquared
