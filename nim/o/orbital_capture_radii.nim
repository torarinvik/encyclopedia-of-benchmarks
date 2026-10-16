## Orbital capture radius from the pinned gravitational-focusing formula.
import std/math

proc roundNonnegative(value: float64): float64 =
  if value >= 9_007_199_254_740_992.0: return value
  let lower = floor(value)
  let fraction = value - lower
  let lowerHalf = floor(lower / 2.0)
  let odd = lower - 2.0 * lowerHalf != 0.0
  if fraction > 0.5 or (fraction == 0.5 and odd): return lower + 1.0
  lower

proc orbital_capture_radii*(radius, mass, velocity: float64): float64 {.cdecl, exportc: "orbital_capture_radii".} =
  if not (radius >= 1.0e-6 and radius <= 1.0e10) or not (mass >= 0.0 and mass <= 2.0e30) or not (velocity >= 1.0e6 and velocity <= 299792458.0): return -1.0e300
  let escapeVelocitySquared = (2.0 * 6.67430e-11 * mass) / radius
  let captureRadius = radius * sqrt(1.0 + escapeVelocitySquared / (velocity * velocity))
  roundNonnegative(captureRadius)
