proc sum_of_odd_numbers*(n: int64): int64 {.cdecl, exportc: "sum_of_odd_numbers".} =
  if n < 0 or n > 46340: return -1
  return n * n
