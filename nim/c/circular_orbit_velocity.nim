import std/math

proc circular_orbit_velocity*(v: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "circular_orbit_velocity".} =
  if v == nil or n != 2: return -1
  let mass=v[0]; let radius=v[1]
  if classify(mass) == fcNan or classify(mass) == fcInf or classify(mass) == fcNegInf or
      classify(radius) == fcNan or classify(radius) == fcInf or classify(radius) == fcNegInf or
      mass < 1.0e-12 or mass > 1.0e25 or radius < 1.0e-12 or radius > 1.0e12: return -1
  if output == nil or capacity < 1: return -2
  output[0]=sqrt(6.67430e-11*mass/radius)
  1
