## Fermat modular division for a bounded prime modulus.
proc modularDivisionIsPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 1
  return true

proc modularDivisionPower(baseInput: int64, exponentInput: uint64, modulus: int64): int64 =
  var base = baseInput mod modulus
  var exponent = exponentInput
  var result = 1'i64
  while exponent != 0:
    if (exponent and 1'u64) != 0: result = (result * base) mod modulus
    exponent = exponent shr 1
    base = (base * base) mod modulus
  return result

proc modular_division*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "modular_division".} =
  if values == nil or length != 3: return -1
  let numerator = values[0]
  let denominator = values[1]
  let modulus = values[2]
  if numerator < 0 or numerator > 1000000000000'i64 or
      denominator < 0 or denominator > 1000000000000'i64 or
      modulus < 2 or modulus > 1000000 or not modularDivisionIsPrime(modulus) or
      denominator mod modulus == 0: return -1
  let inverse = modularDivisionPower(denominator, uint64(modulus - 2), modulus)
  return ((numerator mod modulus) * inverse) mod modulus
