## Floor for bounded finite binary64 inputs, correcting truncation below zero.
proc floor*(value: float64): float64 {.cdecl, exportc: "floor".} =
  if value < -1_000_000.0 or value > 1_000_000.0:
    return -1.0
  var truncated = int64(value)
  if value < float64(truncated):
    dec truncated
  return float64(truncated)
