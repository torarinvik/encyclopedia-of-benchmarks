## Solve the unknown resistance in a balanced Wheatstone bridge.
proc wheatstone_bridge*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "wheatstone_bridge".} =
  if values == nil or length != 3: return -1.0e300
  let resistance1 = values[0]
  let resistance2 = values[1]
  let resistance3 = values[2]
  if resistance1 < 1 or resistance1 > 1_000_000 or resistance2 < 1 or resistance2 > 1_000_000 or resistance3 < 1 or resistance3 > 1_000_000:
    return -1.0e300
  (float64(resistance2) / float64(resistance1)) * float64(resistance3)
