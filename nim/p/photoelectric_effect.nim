## Photoelectric maximum electron kinetic energy in electronvolts.
proc photoelectric_effect*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "photoelectric_effect".} =
  if values == nil or length != 2: return -1.0e300
  let frequency = values[0]
  let workFunction = values[1]
  if frequency < 0 or frequency > 1000000000000000000'i64 or workFunction < 0 or workFunction > 1000: return -1.0e300
  const planckEv = 4.1357e-15
  let photonEnergy = planckEv * float64(frequency)
  let energyDifference = photonEnergy - float64(workFunction)
  if energyDifference > 0.0: return energyDifference
  0.0
