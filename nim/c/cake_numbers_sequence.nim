proc cake_numbers_sequence*(n: int64): int64 {.cdecl, exportc: "cake_numbers_sequence".} =
  if n < 0 or n > 2000000'i64: return -1
  return (n * n * n + 5 * n + 6) div 6
