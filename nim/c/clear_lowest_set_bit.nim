proc clear_lowest_set_bit*(value: int64): int64 {.cdecl, exportc: "clear_lowest_set_bit".} =
  if value < 0 or value > 2147483647'i64: return -1
  return value and (value - 1)
