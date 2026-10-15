import std/math

proc sin_degrees*(angle_value: float64): float64 {.cdecl, exportc: "sin_degrees".} =
  if not (angle_value >= -1_000_000.0 and angle_value <= 1_000_000.0): return -1.0

  let angle = angle_value - floor(angle_value / 360.0) * 360.0
  let radians = angle * (PI / 180.0)
  var result = radians
  var sign = -1.0
  var exponent = 3
  for _ in 0 ..< 18:
    var factorial = 1.0
    for factor in 2 .. exponent: factorial *= float64(factor)
    result += sign * pow(radians, float64(exponent)) / factorial
    sign = -sign
    exponent += 2
  round(result * 10_000_000_000.0) / 10_000_000_000.0
