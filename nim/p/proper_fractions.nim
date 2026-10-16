## Emit reduced proper fractions for one positive denominator.
proc gcd(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc decimalWidth(valueInput: int64): int =
  var value = valueInput
  result = 1
  while value >= 10:
    value = value div 10
    inc result

proc appendDecimal(output: ptr UncheckedArray[uint8], positionInput: int,
                   valueInput: int64): int =
  var value = valueInput
  var digits: array[20, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  result = positionInput
  while count > 0:
    dec count
    output[result] = uint8('0') + digits[count]
    inc result

proc proper_fractions*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "proper_fractions".} =
  if values == nil or length != 1: return -1
  let denominator = values[0]
  if denominator < 0 or denominator > 256: return -1
  if denominator <= 1: return 0
  var needed = 0
  var numerator = 1'i64
  while numerator < denominator:
    if gcd(numerator, denominator) == 1:
      needed += decimalWidth(numerator) + decimalWidth(denominator) + 2
    inc numerator
  if output == nil or outputCapacity < csize_t(needed): return -2
  var position = 0
  numerator = 1
  while numerator < denominator:
    if gcd(numerator, denominator) == 1:
      position = appendDecimal(output, position, numerator)
      output[position] = uint8('/'); inc position
      position = appendDecimal(output, position, denominator)
      output[position] = uint8('\n'); inc position
    inc numerator
  int64(position)
