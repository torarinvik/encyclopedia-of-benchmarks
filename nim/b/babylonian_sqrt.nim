proc babylonian_sqrt*(input: float64): float64 {.cdecl, exportc: "babylonian_sqrt".} =
  if not (input >= 0.0 and input <= 1_000_000.0): return -1.0
  var estimate = input / 2.0
  const tolerance = 0.000001
  while tolerance <= abs(estimate * estimate - input):
    estimate = 0.5 * (estimate + input / estimate)
  estimate
