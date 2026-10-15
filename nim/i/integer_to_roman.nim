## Encode an integer in canonical uppercase Roman numerals.
proc romanDigitLength(digit: int64): csize_t =
  if digit == 4 or digit == 9: return 2
  if digit >= 5: return csize_t(digit - 4)
  csize_t(digit)

proc appendRomanDigit(digitValue: int64, one, five, ten: uint8,
    output: ptr UncheckedArray[uint8], positionValue: csize_t): csize_t =
  var digit = digitValue
  var position = positionValue
  if digit == 9:
    output[position] = one
    output[position + 1] = ten
    return position + 2
  if digit >= 5:
    output[position] = five
    inc position
    digit -= 5
  if digit == 4:
    output[position] = one
    output[position + 1] = five
    return position + 2
  while digit > 0:
    output[position] = one
    inc position
    dec digit
  position

proc integer_to_roman*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "integer_to_roman".} =
  if value < 1 or value > 3999: return -1
  let width = csize_t(value div 1000) + romanDigitLength((value div 100) mod 10) +
    romanDigitLength((value div 10) mod 10) + romanDigitLength(value mod 10)
  if output == nil or outputCapacity < width: return -2
  var position = csize_t(0)
  var thousands = value div 1000
  while thousands > 0:
    output[position] = uint8('M')
    inc position
    dec thousands
  position = appendRomanDigit((value div 100) mod 10, uint8('C'), uint8('D'), uint8('M'), output, position)
  position = appendRomanDigit((value div 10) mod 10, uint8('X'), uint8('L'), uint8('C'), output, position)
  position = appendRomanDigit(value mod 10, uint8('I'), uint8('V'), uint8('X'), output, position)
  int64(position)
