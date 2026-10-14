## Find the smallest prime strictly greater than the input.
proc isPrime(value: int64): bool =
  if value < 2: return false
  if value == 2: return true
  if value mod 2 == 0: return false
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 2
  true

proc next_prime_number*(value: int64): int64 {.cdecl, exportc: "next_prime_number".} =
  if value < -4096 or value > 4096: return -1
  var candidate = value + 1
  if candidate < 2: candidate = 2
  while not isPrime(candidate): inc candidate
  candidate
