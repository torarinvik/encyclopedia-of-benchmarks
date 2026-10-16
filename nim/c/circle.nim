## Perimeter and area calculations for a bounded circle radius.
const InvalidResult = -1.0e300
const Pi = 3.14159265358979323846

proc circle*(radius, operation: float64): float64 {.cdecl, exportc: "circle".} =
  if not (radius >= -1_000_000.0 and radius <= 1_000_000.0 and
      (operation == 0.0 or operation == 1.0)):
    return InvalidResult
  if operation == 0.0: return radius * 2.0 * Pi
  radius * radius * Pi
