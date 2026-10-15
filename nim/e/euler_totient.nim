## Euler's totient via distinct-prime factorization.
proc euler_totient*(n: int64): int64 {.cdecl, exportc: "euler_totient".} =
  if n < 1 or n > 1000000: return -1
  var result = n
  var remaining = n
  var factor = 2'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      while remaining mod factor == 0: remaining = remaining div factor
      result -= result div factor
    inc factor
  if remaining > 1: result -= result div remaining
  result
