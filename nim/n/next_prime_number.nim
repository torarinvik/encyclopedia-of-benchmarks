## Find the smallest prime strictly greater than the input.
proc isCandidatePrime(value: uint32): bool =
  if value mod 3 == 0: return false
  var divisor = 5'u32
  while divisor * divisor <= value:
    if value mod divisor == 0 or value mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc next_prime_number*(value: int64): int64 {.cdecl, exportc: "next_prime_number".} =
  if value < -4096 or value > 4096: return -1
  if value < 2: return 2
  if value == 2: return 3
  var candidate = uint32(value + 1) or 1'u32
  while not isCandidatePrime(candidate): candidate += 2
  int64(candidate)
