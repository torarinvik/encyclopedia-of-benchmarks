## Count low-order zero bits by shifting away factors of two.
proc binary_count_trailing_zeros*(n: int64): int64 {.cdecl, exportc: "binary_count_trailing_zeros".} =
  if n < 0:
    return -1
  var remaining = n
  var count = 0'i64
  while remaining > 0 and remaining mod 2 == 0:
    remaining = remaining div 2
    inc count
  return count
