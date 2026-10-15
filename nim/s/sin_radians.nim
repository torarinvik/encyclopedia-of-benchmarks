import std/math

proc sin_radians*(radians: float64): float64 {.cdecl, exportc: "sin_radians".} =
  if not (radians >= -1_000_000.0 and radians <= 1_000_000.0): return -1.0
  var x = (3.141592653589793 / 2.0) - radians
  let tp = 1.0 / (2.0 * 3.141592653589793)
  x *= tp
  x -= 0.25 + floor(x + 0.25)
  x *= 16.0 * (abs(x) - 0.5)
  x += 0.225 * x * (abs(x) - 1.0)
  return x
