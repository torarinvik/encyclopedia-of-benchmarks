proc liters_to_imperial_gallons*(liters: float64): float64 {.cdecl, exportc: "liters_to_imperial_gallons".} =
  if classify(liters) == fcNan or liters < -1.0e100 or liters > 1.0e100: return -1.0e300
  liters / 4.54609
