proc laplacian_filter(v: ptr UncheckedArray[int64], n: csize_t): float64 {.exportc, dynlib.} =
 if n != 9: return -1.0e300
 for i in 0..<9:
  if v[i] < 0 or v[i] > 255: return -1.0e300
 float64(4*v[4]-v[1]-v[3]-v[5]-v[7])
