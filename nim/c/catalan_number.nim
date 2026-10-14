## Return the exact zero-based Catalan number through the signed 64-bit range.
proc gcdI64(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

proc catalan_number*(n: int64): int64 {.cdecl, exportc: "catalan_number".} =
  if n < 0 or n > 35: return -1

  var value = 1'i64
  var index = 1'i64
  while index <= n:
    var numerator = 4 * index - 2
    var denominator = index + 1
    let common = gcdI64(numerator, denominator)
    numerator = numerator div common
    denominator = denominator div common
    value = (value div denominator) * numerator
    index += 1
  return value
