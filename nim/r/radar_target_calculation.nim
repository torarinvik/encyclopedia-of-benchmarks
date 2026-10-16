import std/math

const
  Wgs84A = 6378137.0
  Wgs84B = 6356752.314245
  PiValue = 3.14159265358979323846

proc radar_target_calculation*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "radar_target_calculation".} =
  if values == nil or length != 6: return -1
  for i in 0 ..< 6:
    if values[i] != values[i]: return -1

  let radarLat = values[0]
  let radarLon = values[1]
  let radarAlt = values[2]
  let azimuthDeg = values[3]
  let rangeM = values[4]
  let elevationDeg = values[5]
  if radarLat < -80.0 or radarLat > 80.0: return -1
  if radarLon < -180.0 or radarLon > 180.0: return -1
  if radarAlt < -1000.0 or radarAlt > 10000.0: return -1
  if azimuthDeg < -360.0 or azimuthDeg > 360.0: return -1
  if rangeM < 0.0 or rangeM > 200000.0: return -1
  if elevationDeg < -30.0 or elevationDeg > 30.0: return -1

  let aSquared = Wgs84A * Wgs84A
  let bSquared = Wgs84B * Wgs84B
  let eSquared = 1.0 - (bSquared / aSquared)
  let epSquared = (aSquared - bSquared) / bSquared
  let azRad = azimuthDeg * PiValue / 180.0
  let elRad = elevationDeg * PiValue / 180.0
  let east = rangeM * cos(elRad) * sin(azRad)
  let north = rangeM * cos(elRad) * cos(azRad)
  let up = rangeM * sin(elRad)

  let latRad = radarLat * PiValue / 180.0
  let lonRad = radarLon * PiValue / 180.0
  let sinLat = sin(latRad)
  let cosLat = cos(latRad)
  let nRadius = Wgs84A / sqrt(1.0 - eSquared * sinLat * sinLat)
  let radarX = (nRadius + radarAlt) * cosLat * cos(lonRad)
  let radarY = (nRadius + radarAlt) * cosLat * sin(lonRad)
  let radarZ = (nRadius * (1.0 - eSquared) + radarAlt) * sinLat

  let sinLon = sin(lonRad)
  let cosLon = cos(lonRad)
  let dx = -sinLon * east - sinLat * cosLon * north + cosLat * cosLon * up
  let dy = cosLon * east - sinLat * sinLon * north + cosLat * sinLon * up
  let dz = cosLat * north + sinLat * up
  let targetX = radarX + dx
  let targetY = radarY + dy
  let targetZ = radarZ + dz

  let p = sqrt(targetX * targetX + targetY * targetY)
  var targetLat, targetLon, targetAlt: float64
  if p == 0.0:
    targetLon = 0.0
    targetLat = if targetZ > 0.0: 90.0 else: -90.0
    targetAlt = abs(targetZ) - Wgs84B
  else:
    let theta = arctan2(targetZ * Wgs84A, p * Wgs84B)
    let sinTheta = sin(theta)
    let cosTheta = cos(theta)
    let targetLonRad = arctan2(targetY, targetX)
    let sinThetaCubed = sinTheta * sinTheta * sinTheta
    let cosThetaCubed = cosTheta * cosTheta * cosTheta
    let targetLatRad = arctan2(
      targetZ + epSquared * Wgs84B * sinThetaCubed,
      p - eSquared * Wgs84A * cosThetaCubed)
    let targetSinLat = sin(targetLatRad)
    let targetNRadius = Wgs84A / sqrt(1.0 - eSquared * targetSinLat * targetSinLat)
    targetAlt = (p / cos(targetLatRad)) - targetNRadius
    targetLat = targetLatRad * 180.0 / PiValue
    targetLon = targetLonRad * 180.0 / PiValue

  if output == nil or capacity < 3: return -2
  output[0] = targetLat
  output[1] = targetLon
  output[2] = targetAlt
  3
