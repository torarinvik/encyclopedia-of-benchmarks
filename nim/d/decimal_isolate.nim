proc decimal_isolate*(input: float64): float64 {.cdecl, exportc: "decimal_isolate".} =
  if not (input > 0.0 and input <= 999_999.0): return -1.0
  let scaledValue = input * 10_000.0
  let scaled = int64(scaledValue)
  if float64(scaled) != scaledValue or float64(scaled) / 10_000.0 != input:
    return -1.0
  if scaled mod 625 != 0 or scaled mod 10_000 == 0: return -1.0
  float64(scaled mod 10_000) / 10_000.0
