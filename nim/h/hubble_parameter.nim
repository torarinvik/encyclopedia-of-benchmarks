import std/math

const InvalidResult = -1.0e300

proc hubble_parameter*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "hubble_parameter".} =
  if values == nil or length != 5: return InvalidResult
  let h0x10 = values[0]
  let radiationPpm = values[1]
  let matterPpm = values[2]
  let darkEnergyPpm = values[3]
  let redshiftMilli = values[4]
  if h0x10 < -2000 or h0x10 > 2000 or radiationPpm < 0 or radiationPpm > 1_000_000 or
      matterPpm < 0 or matterPpm > 1_000_000 or darkEnergyPpm < 0 or darkEnergyPpm > 1_000_000 or
      radiationPpm + matterPpm + darkEnergyPpm > 1_000_000 or redshiftMilli < 0 or redshiftMilli > 10_000: return InvalidResult
  let hubbleConstant = float64(h0x10) / 10.0
  let radiationDensity = float64(radiationPpm) / 1_000_000.0
  let matterDensity = float64(matterPpm) / 1_000_000.0
  let darkEnergy = float64(darkEnergyPpm) / 1_000_000.0
  let redshift = float64(redshiftMilli) / 1_000.0
  let curvature = 1.0 - (matterDensity + radiationDensity + darkEnergy)
  let z1 = redshift + 1.0
  let e2 = radiationDensity * pow(z1, 4.0) + matterDensity * pow(z1, 3.0) + curvature * pow(z1, 2.0) + darkEnergy
  hubbleConstant * pow(e2, 1.0 / 2.0)
