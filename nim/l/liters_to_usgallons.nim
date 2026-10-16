proc liters_to_usgallons*(liters: float64): float64 {.cdecl, exportc: "liters_to_usgallons".} =
  if classify(liters) == fcNan or liters < -1.0e100 or liters > 1.0e100: return -1.0e300
  liters / 3.785411784
