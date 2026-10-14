## Positive powers of four within the signed 32-bit source domain.
proc power_of_four*(value: int64): int64 {.cdecl, exportc: "power_of_four".} =
  if value < -2147483648'i64 or value > 2147483647'i64: return -1
  if value <= 0 or (value and (value - 1)) != 0: return 0
  if (value and 1431655765'i64) != 0: 1 else: 0
