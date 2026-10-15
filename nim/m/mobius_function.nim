## Return the Möbius function for a bounded positive integer.
proc mobius_function*(n: int64): int64 {.cdecl, exportc: "mobius_function".} =
  if n < 1 or n > 10000: return low(int64)
  var remaining = n
  var distinctFactorCount = 0'i64
  var factor = 2'i64
  while factor * factor <= remaining:
    if remaining mod factor == 0:
      remaining = remaining div factor
      if remaining mod factor == 0: return 0
      inc distinctFactorCount
    inc factor
  if remaining > 1: inc distinctFactorCount
  if distinctFactorCount mod 2 == 0: return 1
  -1
