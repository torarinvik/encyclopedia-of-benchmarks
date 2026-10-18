## Greatest prime factor over the bounded primelib input domain.
proc is_prime_trial(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  return true

proc greatest_prime_factor*(n: int64): int64 {.cdecl, exportc: "greatest_prime_factor".} =
  if n < 0 or n > 1_000_000'i64: return -1
  if n < 2: return n
  if is_prime_trial(n): return n

  var quotient = n
  var largest = 0'i64
  var factor = 2'i64
  while quotient != 1:
    if is_prime_trial(factor) and quotient mod factor == 0:
      largest = factor
      quotient = quotient div factor
    else:
      inc factor
  return largest
