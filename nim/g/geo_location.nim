import std/math

proc geo_location*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "geo_location".} =
  if values == nil or length != 4: return -1
  for i in 0 ..< 4:
    if classify(values[i]) == fcNan or classify(values[i]) == fcInf or classify(values[i]) == fcNegInf: return -1
  let lat1d = values[0]; let lon1d = values[1]; let lat2d = values[2]; let lon2d = values[3]
  if lat1d < -90.0 or lat1d > 90.0 or lat2d < -90.0 or lat2d > 90.0 or
      lon1d < -180.0 or lon1d > 180.0 or lon2d < -180.0 or lon2d > 180.0: return -1
  let factor = PI / 180.0
  let lat1 = lat1d * factor; let lon1 = lon1d * factor
  let lat2 = lat2d * factor; let lon2 = lon2d * factor
  let diffLat = lat2 - lat1; let diffLon = lon2 - lon1
  let sinLat = sin(diffLat / 2.0); let sinLon = sin(diffLon / 2.0)
  let haversine = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon
  if haversine < 0.0 or haversine > 1.0: return -1
  if output == nil or capacity < 1: return -2
  output[0] = 6371010.0 * (2.0 * arctan2(sqrt(haversine), sqrt(1.0 - haversine)))
  1
