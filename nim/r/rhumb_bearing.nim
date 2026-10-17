import std/math

const PiValue = 3.14159265358979323846264338327950288

proc rhumb_bearing*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rhumb_bearing".} =
  if input.isNil or inputLength != csize_t(4): return -1
  let lat1 = input[0]; let long1 = input[1]; let lat2 = input[2]; let long2 = input[3]
  if lat1 != lat1 or long1 != long1 or lat2 != lat2 or long2 != long2 or
     abs(lat1) > 1e308 or abs(long1) > 1e308 or abs(lat2) > 1e308 or abs(long2) > 1e308 or
     lat1 < -85.0 or lat1 > 85.0 or lat2 < -85.0 or lat2 > 85.0 or
     long1 < -180.0 or long1 > 180.0 or long2 < -180.0 or long2 > 180.0: return -1
  let phi1 = lat1 * PiValue / 180.0
  let phi2 = lat2 * PiValue / 180.0
  var delLambda = (long2 - long1) * PiValue / 180.0
  if delLambda > PiValue: delLambda -= 2.0 * PiValue
  elif delLambda < -PiValue: delLambda += 2.0 * PiValue
  let delPsi = ln(tan(phi2 / 2.0 + PiValue / 4.0) / tan(phi1 / 2.0 + PiValue / 4.0))
  let bearing = arctan2(delLambda, delPsi) * 180.0 / PiValue
  let bearingPlus360 = bearing + 360.0
  let normalized = bearingPlus360 - floor(bearingPlus360 / 360.0) * 360.0
  if output.isNil or outputCapacity < csize_t(1): return -2
  output[0] = normalized
  1
