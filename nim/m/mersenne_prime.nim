proc isPrimeI64(n: int64): bool =
  if n < 2: return false
  if n mod 2 == 0: return n == 2
  var factor = 3'i64
  while factor <= n div factor:
    if n mod factor == 0: return false
    factor += 2
  return true

proc mersenne_prime*(n: int64): int64 {.cdecl, exportc: "mersenne_prime".} =
  if n == 0: return 0
  if n < 0 or n > 2147483647'i64: return -1
  var remaining = n + 1
  while remaining mod 2 == 0: remaining = remaining div 2
  if remaining != 1: return 0
  return (if isPrimeI64(n): 1 else: 0)
