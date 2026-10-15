import std/math

proc binary_length*(value: int64): int64 {.cdecl, exportc: "binary_length".} =
  if value <= 0 or value > 2147483647'i64: return -1
  return int64(floor(log2(float64(value)))) + 1
