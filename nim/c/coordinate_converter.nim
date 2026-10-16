import std/math

const CoordinateLimit = 1_000_000.0
const AngleLimitDegrees = 36_000.0
const DegreesPerRadian = 57.2957795130823208768
const RadiansPerDegree = 0.0174532925199432957692
const InvalidResult = -1.0e300

proc coordinate_converter*(first, second, component: float64): float64
    {.cdecl, exportc: "coordinate_converter".} =
  if component == 0.0 or component == 1.0:
    if first != first or second != second or
        first < -CoordinateLimit or first > CoordinateLimit or
        second < -CoordinateLimit or second > CoordinateLimit:
      return InvalidResult
    if component == 0.0: return sqrt(first * first + second * second)
    return arctan2(second, first) * DegreesPerRadian
  if component == 2.0 or component == 3.0:
    if first != first or second != second or
        first < 0.0 or first > CoordinateLimit or
        second < -AngleLimitDegrees or second > AngleLimitDegrees:
      return InvalidResult
    let radians = second * RadiansPerDegree
    return first * (if component == 2.0: cos(radians) else: sin(radians))
  return InvalidResult
