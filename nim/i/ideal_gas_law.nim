## Pressure from the ideal gas law: n * T * R / V.
proc ideal_gas_law*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ideal_gas_law".} =
  if length != 3 or values == nil: return -1.0e300
  let moles = values[0]
  let kelvin = values[1]
  let volume = values[2]
  if moles < 0 or moles > 1000 or kelvin < 0 or kelvin > 1000 or volume < 1 or volume > 1000:
    return -1.0e300
  (float64(moles) * float64(kelvin) * 8.314462) / float64(volume)
