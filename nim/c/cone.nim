## Selected volume or total surface area of a circular cone.
import std/math

proc cone*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "cone".} =
  if values == nil or length != 3: return -1.0e300
  let operation = values[0]
  let radius = values[1]
  let height = values[2]
  if (operation != 0 and operation != 1) or radius < 0 or radius > 1000 or
      height < 0 or height > 1000: return -1.0e300
  const pi = 3.14159265358979323846
  let radiusValue = float64(radius)
  let radiusSquared = radiusValue * radiusValue
  let baseArea = radiusSquared * pi
  if operation == 0: return (baseArea * float64(height) * 1.0) / 3.0
  let heightValue = float64(height)
  baseArea + pi * radiusValue * sqrt(radiusSquared + heightValue * heightValue)
