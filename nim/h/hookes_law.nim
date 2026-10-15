## Hooke's law restoring force: -spring_constant * displacement.
proc hookes_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "hookes_law".} =
  if length != 2 or values == nil: return -1.0e300
  let springConstant = values[0]
  let displacement = values[1]
  if springConstant < 1 or springConstant > 1000 or displacement < -1000 or displacement > 1000:
    return -1.0e300
  (-float64(springConstant)) * float64(displacement)
