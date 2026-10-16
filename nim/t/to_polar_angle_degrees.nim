## Match the pinned MATLAB to_polar angle formula in degrees.
import std/math

const InvalidResult = -1.0e300
const PiValue = 3.141592653589793238462643383279502884

proc to_polar_angle_degrees*(x, y: float64): float64 {.cdecl, exportc: "to_polar_angle_degrees".} =
  if x != x or y != y or x < -1_000_000.0 or x > 1_000_000.0 or
      y < -1_000_000.0 or y > 1_000_000.0 or (x == 0.0 and y == 0.0):
    return InvalidResult
  let theta = if x >= 0.0: arctan(y / x) else: arctan(y / x) + PiValue
  theta * (180.0 / PiValue)
