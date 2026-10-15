## Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
proc kinetic_energy*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "kinetic_energy".} =
  if length != 2 or values == nil: return -1.0e300
  let mass = values[0]
  let velocity = values[1]
  if mass < 0 or mass > 1000 or velocity < -1000 or velocity > 1000:
    return -1.0e300
  let speed = if velocity < 0: -velocity else: velocity
  ((0.5 * float64(mass)) * float64(speed)) * float64(speed)
