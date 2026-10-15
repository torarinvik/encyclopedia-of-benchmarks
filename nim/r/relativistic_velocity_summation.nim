const SpeedOfLight = 299792458'i64
const InvalidResult = -1.0e300

proc relativistic_velocity_summation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "relativistic_velocity_summation".} =
  if values == nil or length != 2: return InvalidResult
  let objectVelocity = values[0]
  let frameVelocity = values[1]
  if objectVelocity < -SpeedOfLight or objectVelocity > SpeedOfLight or
      frameVelocity < -(SpeedOfLight - 1) or frameVelocity > SpeedOfLight - 1:
    return InvalidResult
  let numerator = objectVelocity + frameVelocity
  let cSquared = SpeedOfLight * SpeedOfLight
  let denominator = 1.0 + float64(objectVelocity * frameVelocity) / float64(cSquared)
  float64(numerator) / denominator
