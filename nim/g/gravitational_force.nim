import std/math

proc gravitational_force*(v: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "gravitational_force".} =
  if v == nil or n != 6: return -1
  for i in 0 ..< 6:
    if classify(v[i]) == fcNan or classify(v[i]) == fcInf or classify(v[i]) == fcNegInf: return -1
  let m1=v[0]; let x1=v[1]; let y1=v[2]; let m2=v[3]; let x2=v[4]; let y2=v[5]
  if m1 > 1.0e12 or m1 < -1.0e12 or m2 > 1.0e12 or m2 < -1.0e12 or
      (m1 != 0.0 and abs(m1) < 1.0e-12) or (m2 != 0.0 and abs(m2) < 1.0e-12) or
      abs(x1)>1.0e6 or abs(y1)>1.0e6 or abs(x2)>1.0e6 or abs(y2)>1.0e6: return -1
  let dx=x1-x2; let dy=y1-y2; let d2=dx*dx+dy*dy
  if d2 != 0.0 and d2 < 1.0e-12: return -1
  if output == nil or capacity < 2: return -2
  if d2 == 0.0:
    output[0]=0.0; output[1]=0.0
    return 2
  let distance=sqrt(d2)
  let magnitude=6.67430e-11*m1*m2/d2
  output[0]=magnitude*(dx/distance); output[1]=magnitude*(dy/distance)
  2
