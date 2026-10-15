## Convert radians to degrees using the pinned expression order.
proc radian_to_degree*(radian: float64): float64 {.cdecl, exportc: "radian_to_degree".} =
  if not (radian >= -1_000_000.0 and radian <= 1_000_000.0): return -1.0e300
  radian * (180.0 / 3.141592653589793)
