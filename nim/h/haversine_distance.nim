import std/math

const InvalidResult = -1.0e300
const PiValue = 3.14159265358979323846264338327950288

proc validCoordinates(values: ptr UncheckedArray[int64], length: csize_t): bool =
  if values == nil or length != 4: return false
  if values[0] < -90000000 or values[0] > 90000000: return false
  if values[2] < -90000000 or values[2] > 90000000: return false
  if values[1] < -180000000 or values[1] > 180000000: return false
  if values[3] < -180000000 or values[3] > 180000000: return false
  true

proc haversineA(values: ptr UncheckedArray[int64]): float64 =
  let radiansPerMicrodegree = PiValue / 180000000.0
  let latitude1 = float64(values[0]) * radiansPerMicrodegree
  let longitude1 = float64(values[1]) * radiansPerMicrodegree
  let latitude2 = float64(values[2]) * radiansPerMicrodegree
  let longitude2 = float64(values[3]) * radiansPerMicrodegree
  let deltaLatitude = latitude2 - latitude1
  let deltaLongitude = longitude2 - longitude1
  let sinLatitude = sin(deltaLatitude / 2.0)
  let sinLongitude = sin(deltaLongitude / 2.0)
  var a = sinLatitude * sinLatitude +
    cos(latitude1) * cos(latitude2) * sinLongitude * sinLongitude
  if a < 0.0: a = 0.0
  if a > 1.0: a = 1.0
  a

## Source-derived spherical distance operation.
proc haversine_distance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "haversine_distance".} =
  if not validCoordinates(values, length): return InvalidResult
  let a = haversineA(values)
  2.0 * arctan2(sqrt(a), sqrt(1.0 - a)) * 6371.0
