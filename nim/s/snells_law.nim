import std/math

const PiValue = 3.141592653589793238462643383279502884

proc roundTwoEven(value: float64): float64 =
  let scaled = value * 100.0
  let lower = floor(scaled)
  let fraction = scaled - lower
  var rounded = int64(lower)
  if fraction > 0.5 or (fraction == 0.5 and rounded mod 2 != 0):
    inc rounded
  float64(rounded) / 100.0

proc snells_law*(n1, n2, incident_angle_degrees: float64): float64
    {.cdecl, exportc: "snells_law".} =
  if classify(n1) == fcNan or classify(n2) == fcNan or classify(incident_angle_degrees) == fcNan or
      n1 < 0.5 or n1 > 2.5 or n2 < 0.5 or n2 > 2.5 or
      incident_angle_degrees < -90.0 or incident_angle_degrees > 90.0:
    return -1.0e300
  let incidentAngleRadians = incident_angle_degrees * (PiValue / 180.0)
  let refractionSine = (n1 / n2) * sin(incidentAngleRadians)
  let scale = max(abs(refractionSine), 1.0)
  if abs(refractionSine - 1.0) <= 1.0e-9 * scale: return 90.0
  if abs(refractionSine + 1.0) <= 1.0e-9 * scale: return -90.0
  if refractionSine < -1.0 or refractionSine > 1.0: return -1.0e300
  let refractionAngleDegrees = arcsin(refractionSine) * (180.0 / PiValue)
  roundTwoEven(refractionAngleDegrees)
