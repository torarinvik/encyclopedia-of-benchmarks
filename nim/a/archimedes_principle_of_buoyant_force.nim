## Buoyant force: fluid density * gravity * displaced volume.
proc archimedes_principle_of_buoyant_force*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "archimedes_principle_of_buoyant_force".} =
  if length != 2 or values == nil: return -1.0e300
  let fluidDensity = values[0]
  let volume = values[1]
  if fluidDensity < 1 or fluidDensity > 1000 or volume < 1 or volume > 1000:
    return -1.0e300
  (float64(fluidDensity) * 9.80665) * float64(volume)
