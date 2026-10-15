import std/math

const SpeedOfLight = 299792458'i64
const InvalidResult = -1.0e300

proc relativistic_kinetic_energy*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "relativistic_kinetic_energy".} =
  if values == nil or length != 2: return InvalidResult
  let mass = values[0]
  let velocity = values[1]
  if mass < 0 or mass > 1_000_000 or velocity < -(SpeedOfLight - 1) or velocity > SpeedOfLight - 1:
    return InvalidResult
  let cSquared = SpeedOfLight * SpeedOfLight
  let gamma = 1.0 / sqrt(1.0 - float64(velocity * velocity) / float64(cSquared))
  (gamma - 1.0) * float64(mass) * float64(cSquared)
