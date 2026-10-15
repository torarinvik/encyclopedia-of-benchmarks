## Return whether positive n has no repeated prime factor.
proc is_square_free*(n: int64): int64 {.cdecl, exportc: "is_square_free".} =
  if n < 1 or n > 1_000_000: return -1
  var remaining = n
  var factor = 2'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      remaining = remaining div factor
      if remaining mod factor == 0: return 0
    inc factor
  return 1
