## Return the unpadded decimal suffix of the non-Mersenne prime expression.
const MaxDigits = 18'i64
const PowerExponent = 7_830_457'i64

proc multiplyMod(leftValue, rightValue, modulus: int64): int64 =
  var left = leftValue
  var right = rightValue
  var resultValue = 0'i64
  while right > 0:
    if right mod 2 != 0: resultValue = (resultValue + left) mod modulus
    left = (left + left) mod modulus
    right = right div 2
  resultValue

proc problem97*(digits: int64): int64 {.cdecl, exportc: "problem97".} =
  if digits < 0 or digits > MaxDigits: return -1
  var modulus = 1'i64
  for index in 0'i64 ..< digits: modulus *= 10
  var power = 1'i64 mod modulus
  var base = 2'i64 mod modulus
  var exponent = PowerExponent
  while exponent > 0:
    if exponent mod 2 != 0: power = multiplyMod(power, base, modulus)
    base = multiplyMod(base, base, modulus)
    exponent = exponent div 2
  (multiplyMod(28_433, power, modulus) + 1) mod modulus
