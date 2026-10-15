## Reynolds number: density * abs(velocity) * diameter / viscosity.
proc reynolds_number*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "reynolds_number".} =
  if length != 4 or values == nil: return -1.0e300
  let density = values[0]
  let velocity = values[1]
  let diameter = values[2]
  let viscosity = values[3]
  if density < 1 or density > 1000 or velocity < -1000 or velocity > 1000 or diameter < 1 or diameter > 1000 or viscosity < 1 or viscosity > 1000:
    return -1.0e300
  let speed = if velocity < 0: -velocity else: velocity
  (((float64(density) * float64(speed)) * float64(diameter)) / float64(viscosity))
