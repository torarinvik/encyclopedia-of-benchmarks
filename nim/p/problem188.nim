proc modexpt(base, exponent, modulus: int64): int64 =
  if exponent == 1: return base
  if exponent mod 2 == 0:
    let half = modexpt(base, exponent div 2, modulus) mod modulus
    return (half * half) mod modulus
  (base * modexpt(base, exponent - 1, modulus)) mod modulus

proc problem188*(base, height, digits: int64): int64 {.cdecl, exportc: "problem188".} =
  if base < 1 or base > 1_000_000_000 or base mod 10 == 0
      or height < 1 or height > 10_000 or digits < 1 or digits > 8: return -1
  var modulus = 1'i64
  for _ in 0 ..< int(digits): modulus *= 10
  var result = base
  for _ in 1 ..< int(height): result = modexpt(base, result, modulus)
  result
