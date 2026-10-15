## Count decimal zero digits at the end of a nonnegative integer.
proc trailing_zeroes*(n: int64): int64 {.cdecl, exportc: "trailing_zeroes".} =
  if n < 0:
    return -1
  if n == 0:
    return 1
  var remaining = n
  var count = 0'i64
  while remaining mod 10 == 0:
    inc count
    remaining = remaining div 10
  return count
