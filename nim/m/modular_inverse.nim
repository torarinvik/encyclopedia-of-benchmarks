proc normalizedMod(value, modulus: int64): int64 =
  var remainder = value mod modulus
  if remainder < 0: remainder += modulus
  remainder

proc modular_inverse*(a, modulus: int64): int64 {.cdecl, exportc: "modular_inverse".} =
  if a < 0 or a > 1_000_000 or modulus < 2 or modulus > 1_000_000:
    return -1

  var oldRemainder = normalizedMod(a, modulus)
  var remainder = modulus
  var oldCoefficient: int64 = 1
  var coefficient: int64 = 0
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldRemainder = remainder
    remainder = nextRemainder
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  if oldRemainder != 1: return -1
  normalizedMod(oldCoefficient, modulus)
