proc max_value*(a, b: int64): int64 {.cdecl, exportc: "max_value".} =
  if a < int64(low(int32)) or a > int64(high(int32)) or
      b < int64(low(int32)) or b > int64(high(int32)): return -1
  if a >= b: a else: b
