## Fermat modular inverse via prime validation and binary exponentiation.
proc isPrime(value: int64): bool =
  if value <= 1: return false
  var divisor = 2'i64
  while divisor * divisor <= value:
    if value mod divisor == 0: return false
    inc divisor
  true

proc binaryExponentiation(baseInput, exponentInput, modulus: int64): int64 =
  var base = baseInput mod modulus
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent div 2
  result

proc modular_inverse_fermat_little_theorem*(a, m: int64): int64
    {.cdecl, exportc: "modular_inverse_fermat_little_theorem".} =
  if a < -1_000_000 or a > 1_000_000 or m < 2 or m > 1_000_000: return -1
  if a == 0 or a <= -m or a >= m or not isPrime(m): return -1
  var normalized = a
  while normalized < 0: normalized += m
  binaryExponentiation(normalized, m - 2, m)
