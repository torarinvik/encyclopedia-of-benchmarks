## Escape velocity with the source's three-decimal result rounding.
import math

proc fma(first, second, third: float64): float64 {.importc: "fma", header: "<math.h>".}

proc roundThreeEven(value: float64): float64 =
  let scaled = value * 1000.0
  let lower = floor(scaled)
  let midpoint = lower + 0.5
  let exactSide = fma(value, 1000.0, -midpoint)
  var rounded = int64(lower)
  if exactSide > 0.0 or (exactSide == 0.0 and rounded mod 2 != 0):
    inc rounded
  result = float64(rounded) / 1000.0

proc escape_velocity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "escape_velocity".} =
  if length != 2 or values == nil: return -1.0e300
  let mass = values[0]
  let radius = values[1]
  if mass < 0 or mass > 1_000_000_000_000_000'i64 or radius < 1 or radius > 1_000_000_000'i64:
    return -1.0e300
  let velocity = sqrt(2.0 * 6.67430e-11 * float64(mass) / float64(radius))
  roundThreeEven(velocity)
