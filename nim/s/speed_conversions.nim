## Convert a bounded speed between the four units in the pinned source.
import std/math

proc fma(first, second, third: float64): float64 {.importc: "fma", header: "<math.h>".}

proc roundThreeEven(value: float64): float64 =
  let lower = floor(value * 1000.0)
  let midpoint = lower + 0.5
  let exactSide = fma(value, 1000.0, -midpoint)
  var rounded = int64(lower)
  if exactSide > 0.0 or (exactSide == 0.0 and rounded mod 2 != 0): inc rounded
  float64(rounded) / 1000.0

proc speed_conversions*(speed, route: float64): float64 {.cdecl, exportc: "speed_conversions".} =
  if speed != speed or route != route or speed < 0.0 or speed > 1_000_000.0 or
      route < 0.0 or route > 15.0 or floor(route) != route: return -1.0
  let factors = [1.0, 3.6, 1.609344, 1.852]
  let inverseFactors = [1.0, 0.277777778, 0.621371192, 0.539956803]
  let encoded = int(route)
  let unitFrom = encoded div 4
  let unitTo = encoded mod 4
  roundThreeEven(speed * factors[unitFrom] * inverseFactors[unitTo])
