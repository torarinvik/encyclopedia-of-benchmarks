## Convert a bounded speed between the five units in the pinned source.
import std/math

proc roundTwoPhp(value: float64): float64 =
  floor(value * 100.0 + 0.5) / 100.0

proc speed_conversion*(speed, route: float64): float64 {.cdecl, exportc: "speed_conversion".} =
  if speed != speed or route != route or speed < 0.0 or speed > 1_000_000.0 or
      route < 0.0 or route > 24.0 or floor(route) != route: return -1.0
  let factors = [1.609344, 1.0, 3.6, 1.097, 1.852]
  let inverseFactors = [0.6213712, 1.0, 0.277778, 0.911344, 0.539957]
  let encoded = int(route)
  let unitFrom = encoded div 5
  let unitTo = encoded mod 5
  roundTwoPhp(speed * factors[unitFrom] * inverseFactors[unitTo])
