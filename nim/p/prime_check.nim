## Trial-division primality check over the shared bounded integer domain.
proc prime_check*(n: int64): int64 {.cdecl, exportc: "prime_check".} =
  if n < 2: return 0
  if n > 2147483647'i64: return -1
  if n mod 2 == 0: return (if n == 2: 1 else: 0)
  var factor = 3'i64
  while factor <= n div factor:
    if n mod factor == 0: return 0
    factor += 2
  return 1
