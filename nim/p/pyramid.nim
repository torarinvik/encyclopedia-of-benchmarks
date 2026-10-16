import math
proc pyramid*(v: ptr int64, n: uint64): float64 {.cdecl, exportc: "pyramid".} =
  if v == nil or n != 3 or v[0] < 0 or v[0] > 1 or v[1] < 1 or v[1] > 10_000_000 or v[2] < 1 or v[2] > 10_000_000: return -1e300
  let b = float64(v[1]) / 1000.0
  let h = float64(v[2]) / 1000.0
  let area = pow(b, 2.0)
  if v[0] == 0: return (area * h) / 3.0
  area + ((b * 4.0) / 2.0) * sqrt(pow(b / 2.0, 2.0) + pow(h, 2.0))
