## Centripetal force: (mass * velocity^2) / radius.
proc centripetal_force*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "centripetal_force".} =
  if length != 3 or values == nil: return -1.0e300
  let mass = values[0]
  let velocity = values[1]
  let radius = values[2]
  if mass < 0 or mass > 1000 or velocity < -1000 or velocity > 1000 or radius < 1 or radius > 1000:
    return -1.0e300
  let velocitySquared = float64(velocity) * float64(velocity)
  (float64(mass) * velocitySquared) / float64(radius)
