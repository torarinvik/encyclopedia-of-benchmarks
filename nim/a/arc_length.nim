## Return arc length; unit 0 uses degrees and unit 1 uses radians.
const Pi64 = 3.141592653589793238462643383279502884

proc arc_length*(radius, angle, unit: float64): float64 {.cdecl, exportc: "arc_length".} =
  if unit == 0.0:
    return 2.0 * Pi64 * radius * (angle / 360.0)
  return radius * angle
