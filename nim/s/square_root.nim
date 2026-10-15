## Newton square root using binary64 arithmetic and a portable initial estimate.
proc square_root*(value: float64): float64 {.cdecl, exportc: "square_root".} =
  if value == 0.0: return 0.0
  var estimate = if value >= 1.0: value else: 1.0
  for iteration in 0 ..< 1100:
    let next = 0.5 * estimate + 0.5 * (value / estimate)
    if next >= estimate: return estimate
    estimate = next
  estimate
