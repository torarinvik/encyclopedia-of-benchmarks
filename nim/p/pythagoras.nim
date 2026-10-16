proc pythagoras*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "pythagoras".} =
 if v.isNil or n != 6: return -1.0e300
 for i in 0..<6:
  if v[i] < -1_000_000 or v[i] > 1_000_000: return -1.0e300
 let dx=float64(v[3]-v[0]);let dy=float64(v[4]-v[1]);let dz=float64(v[5]-v[2])
 sqrt(dx*dx+dy*dy+dz*dz)
