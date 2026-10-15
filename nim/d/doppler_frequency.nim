## Doppler frequency using the bounded integer-valued source contract.
proc doppler_frequency*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doppler_frequency".} =
  if values == nil or length != 4: return -1.0e300
  let orgFreq = values[0]
  let waveVel = values[1]
  let obsVel = values[2]
  let srcVel = values[3]
  if orgFreq < 1 or orgFreq > 1000 or waveVel < 200 or waveVel > 1000 or obsVel < -100 or obsVel > 100 or srcVel < -100 or srcVel > 100:
    return -1.0e300
  (float64(orgFreq) * (float64(waveVel) + float64(obsVel))) / (float64(waveVel) - float64(srcVel))
