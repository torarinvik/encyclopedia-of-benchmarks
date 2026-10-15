## Solve one quantity in conductivity = electron concentration * mobility * charge.
proc electric_conductivity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "electric_conductivity".} =
  if values == nil or length != 3: return -1.0e300
  let conductivity = values[0]
  let electronConc = values[1]
  let mobility = values[2]
  if conductivity < 0 or conductivity > 1000 or electronConc < 0 or electronConc > 1000 or mobility < 0 or mobility > 1000: return -1.0e300
  let zeros = (if conductivity == 0: 1 else: 0) + (if electronConc == 0: 1 else: 0) + (if mobility == 0: 1 else: 0)
  if zeros != 1: return -1.0e300
  const charge = 1.6021e-19
  if conductivity == 0: return float64(mobility) * float64(electronConc) * charge
  if electronConc == 0: return float64(conductivity) / (float64(mobility) * charge)
  float64(conductivity) / (float64(electronConc) * charge)
