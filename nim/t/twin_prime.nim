proc isPrime(value: int64): bool =
  if value < 2: return false
  if value == 2: return true
  if value mod 2 == 0: return false
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc twin_prime*(value: int64): int64 {.cdecl, exportc: "twin_prime".} =
  if value < -4096 or value > 4096: return -1
  if isPrime(value) and isPrime(value + 2): return value + 2
  -1
