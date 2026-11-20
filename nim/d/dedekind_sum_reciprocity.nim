const
  MaxModulus = 100_000'i64
  ResultOffset = 29_999_700_001'i64

proc gcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc scaledSum(numerator, modulus: int64): int64 =
  if modulus == 1: return 0
  let tail = scaledSum(modulus mod numerator, numerator)
  let top = numerator * numerator + modulus * modulus + 1 -
    3 * numerator * modulus - modulus * tail
  top div numerator

proc dedekind_sum_reciprocity*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dedekind_sum_reciprocity".} =
  if input == nil or length != 2: return -1
  let numerator = input[0]
  let modulus = input[1]
  if modulus < 1 or modulus > MaxModulus or numerator < 0 or numerator >= modulus:
    return -1
  if gcd(numerator, modulus) != 1: return -1
  ResultOffset + scaledSum(numerator, modulus)
