## Return a spherical initial bearing in integer microdegrees.
import std/math

proc bearing*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bearing".} =
  if values == nil or length != 4: return -1
  let latitude1Value = values[0]
  let longitude1Value = values[1]
  let latitude2Value = values[2]
  let longitude2Value = values[3]
  if latitude1Value < -90_000_000 or latitude1Value > 90_000_000 or
      latitude2Value < -90_000_000 or latitude2Value > 90_000_000 or
      longitude1Value < -180_000_000 or longitude1Value > 180_000_000 or
      longitude2Value < -180_000_000 or longitude2Value > 180_000_000 or
      (latitude1Value == latitude2Value and longitude1Value == longitude2Value):
    return -1

  const radiansPerMicrodegree = 0.000001 * (PI / 180.0)
  let latitude1 = float64(latitude1Value) * radiansPerMicrodegree
  let longitude1 = float64(longitude1Value) * radiansPerMicrodegree
  let latitude2 = float64(latitude2Value) * radiansPerMicrodegree
  let longitude2 = float64(longitude2Value) * radiansPerMicrodegree
  let deltaLongitude = longitude2 - longitude1
  let east = sin(deltaLongitude) * cos(latitude2)
  let north = cos(latitude1) * sin(latitude2) -
              sin(latitude1) * cos(latitude2) * cos(deltaLongitude)
  var degrees = arctan2(east, north) * (180.0 / PI)
  if degrees < 0.0: degrees += 360.0
  let result = int64(degrees * 1_000_000.0 + 0.5)
  if result >= 360_000_000: return 0
  result
