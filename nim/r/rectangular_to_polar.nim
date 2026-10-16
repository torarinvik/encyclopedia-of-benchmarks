import std/math

const InvalidResult = -1.0e300
const DegreeFactor = 57.2957795130823208768

proc roundTwoAway(value: float64): float64 =
  if value == 0.0: return value
  let scaled = value * 100.0
  if scaled >= 0.0: return float64(int64(scaled + 0.5)) / 100.0
  let units = int64(scaled - 0.5)
  if units == 0: return -0.0
  float64(units) / 100.0

proc rectangular_to_polar*(real, imag, component: float64): float64
    {.cdecl, exportc: "rectangular_to_polar".} =
  if real != real or imag != imag or component != component or
      abs(real) > 1_000_000.0 or abs(imag) > 1_000_000.0 or
      (component != 0.0 and component != 1.0): return InvalidResult
  if component == 0.0: return roundTwoAway(sqrt(real * real + imag * imag))
  roundTwoAway(arctan2(imag, real) * DegreeFactor)
