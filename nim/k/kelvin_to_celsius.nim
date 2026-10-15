proc kelvin_to_celsius*(temperature_in_k: float64): float64 {.cdecl, exportc: "kelvin_to_celsius".} =
  if not (temperature_in_k >= 0.0 and temperature_in_k <= 1_000_000.0): return -1.0
  let absolute_zero_in_c = -273.15
  temperature_in_k + absolute_zero_in_c
