## Circular cross-sectional area for orbital capture, rounded to whole square metres.
import std/math

proc roundNonnegative(value: float64): float64 =
  if value >= 9_007_199_254_740_992.0: return value
  let lower = floor(value)
  let fraction = value - lower
  let lowerHalf = floor(lower / 2.0)
  let odd = lower - 2.0 * lowerHalf != 0.0
  if fraction > 0.5 or (fraction == 0.5 and odd): return lower + 1.0
  lower

proc orbital_capture_area*(captureRadius: float64): float64 {.cdecl, exportc: "orbital_capture_area".} =
  if not (captureRadius >= 0.0 and captureRadius <= 1.0e10): return -1.0e300
  let area = 3.14159265358979323846 * captureRadius * captureRadius
  roundNonnegative(area)
