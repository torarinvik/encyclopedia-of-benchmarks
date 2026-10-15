## Unoptimized trial division under a bounded positive input contract.
proc primeCheckNaive*(n: int64): int64 {.cdecl, exportc: "prime_check_naive".} =
  if n > 10000: return -1
  if n < 2: return 0
  var divisor = 2'i64
  while divisor < n:
    if n mod divisor == 0: return 0
    divisor += 1
  return 1
