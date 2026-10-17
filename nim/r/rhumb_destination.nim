import std/math

const PiValue = 3.14159265358979323846264338327950288
const EarthRadius = 6371000.0

proc rhumb_destination*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rhumb_destination".} =
  if input.isNil or inputLength != csize_t(4): return -1
  let latitude = input[0]; let longitude = input[1]; let distance = input[2]; let bearing = input[3]
  if latitude != latitude or longitude != longitude or distance != distance or bearing != bearing or
     abs(latitude) > 1e308 or abs(longitude) > 1e308 or abs(distance) > 1e308 or abs(bearing) > 1e308 or
     latitude < -80.0 or latitude > 80.0 or longitude < -180.0 or longitude > 180.0 or
     distance < 0.0 or distance > 300000.0 or bearing < 0.0 or bearing > 360.0: return -1
  let del = distance / EarthRadius
  let phi1 = latitude * PiValue / 180.0
  let lambda1 = longitude * PiValue / 180.0
  let theta = bearing * PiValue / 180.0
  let delPhi = del * cos(theta)
  var phi2 = phi1 + delPhi
  if phi2 > PiValue / 2.0: phi2 = PiValue / 2.0
  elif phi2 < -PiValue / 2.0: phi2 = -PiValue / 2.0
  let delPsi = ln(tan(phi2 / 2.0 + PiValue / 4.0) / tan(phi1 / 2.0 + PiValue / 4.0))
  let q = if abs(delPsi) > 1e-12: delPhi / delPsi else: cos(phi1)
  let delLambda = del * sin(theta) / q
  let resultLatitude = phi2 * 180.0 / PiValue
  let resultLongitude = (lambda1 + delLambda) * 180.0 / PiValue
  if output.isNil or outputCapacity < csize_t(2): return -2
  output[0] = resultLatitude; output[1] = resultLongitude
  2
