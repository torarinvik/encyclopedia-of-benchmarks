const MaxInputs = 8
const MaxModulus = 1000'i64

proc modularInverse(value, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var remainder = modulus
  var oldCoefficient = 1'i64
  var coefficient = 0'i64
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  if oldRemainder != 1: return -1
  oldCoefficient = oldCoefficient mod modulus
  if oldCoefficient < 0: oldCoefficient += modulus
  oldCoefficient

proc chinese_remainder_theorem*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "chinese_remainder_theorem".} =
  if length < 2 or length > MaxInputs or length mod 2 != 0: return -1
  var result = 0'i64
  var product = 1'i64
  var index: csize_t = 0
  while index < length:
    let residue = values[index]
    let modulus = values[index + 1]
    if modulus < 2 or modulus > MaxModulus or residue < 0 or residue >= modulus: return -1
    let inverse = modularInverse(product mod modulus, modulus)
    if inverse < 0: return -1
    var difference = residue - result mod modulus
    if difference < 0: difference += modulus
    let factor = (difference * inverse) mod modulus
    result += product * factor
    product *= modulus
    index += 2
  result
