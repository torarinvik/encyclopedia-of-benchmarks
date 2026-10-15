proc celsius_to_fahrenheit*(celsius: float64): float64 {.cdecl, exportc: "celsius_to_fahrenheit".} =
  (celsius * 9.0 / 5.0) + 32.0
