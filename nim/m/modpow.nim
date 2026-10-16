type I64Input = ptr UncheckedArray[int64]
const MaxParseableInputLength = 4
const MaxComponent = 89_000_000'i64
const MaxExponent = 64'i64
const InvalidResult = low(int64)

proc modpow*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "modpow".} =
  if input == nil or length < 3 or length > csize_t(MaxParseableInputLength): return InvalidResult
  if int(length) != 3: return InvalidResult
  var base = input[0]
  var exponent = input[1]
  let modulus = input[2]
  if base < 0 or base > MaxComponent or exponent < 0 or exponent > MaxExponent
      or modulus < 1 or modulus > MaxComponent: return InvalidResult
  if exponent == 0:
    if base == 0: return InvalidResult
    return 1'i64 mod modulus
  if base == 0: return 0
  var result = 1'i64 mod modulus
  while exponent > 0:
    if exponent mod 2 == 1:
      result = (result * base) mod modulus
      dec exponent
    else:
      base = (base * base) mod modulus
      exponent = exponent div 2
  result
