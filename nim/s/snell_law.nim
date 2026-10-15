import std/math

const InvalidResult = -1.0e300
const HalfPi = 1.5707963267948966

proc snell_law*(n1, n2, theta1: float64): float64 {.cdecl, exportc: "snell_law".} =
  if classify(n1) == fcNan or classify(n2) == fcNan or classify(theta1) == fcNan or
      n1 < 0.5 or n1 > 2.5 or n2 < 0.5 or n2 > 2.5 or theta1 < -HalfPi or theta1 > HalfPi:
    return InvalidResult
  let ratio = n1 / n2
  let sinTheta2 = ratio * sin(theta1)
  if abs(sinTheta2) > 1.0: return InvalidResult
  arcsin(sinTheta2)
