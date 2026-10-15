## Multiply a base-10 digit array by each factor through n.
const MaxN = 100
const MaxDigits = 160

proc factorial_large_number*(n: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "factorial_large_number".} =
  if n < 0 or n > MaxN: return -1
  var digits: array[MaxDigits, int64]
  digits[0] = 1
  var digitCount = 1
  var factor = 2'i64
  while factor <= n:
    var carry = 0'i64
    for index in 0 ..< digitCount:
      let product = digits[index] * factor + carry
      digits[index] = product mod 10
      carry = product div 10
    while carry != 0:
      digits[digitCount] = carry mod 10
      inc digitCount
      carry = carry div 10
    inc factor
  if output.isNil or outputCapacity < csize_t(digitCount): return -2
  for index in 0 ..< digitCount:
    output[index] = uint8(ord('0') + int(digits[digitCount - index - 1]))
  int64(digitCount)
