## Sum of a full binomial row, computed as 2^n.
proc sum_of_binomial_coefficient*(n: int64): int64 {.cdecl, exportc: "sum_of_binomial_coefficient".} =
  if n < 0 or n > 30: return -1
  return 1'i64 shl int(n)
