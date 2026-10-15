## Enumerate Kaprekar numbers as decimal NUL-terminated values.
const MaxEnd = 100000'i64

proc isKaprekar(number: int64): bool =
  if number == 0 or number == 1: return true
  let square = number * number
  var split = 1'i64
  var remaining = number
  while remaining > 0:
    split *= 10
    remaining = remaining div 10
  let right = square mod split
  right != 0 and square div split + right == number

proc decimalLength(numberValue: int64): csize_t =
  var number = numberValue
  result = 1
  while number >= 10:
    number = number div 10
    inc result

proc requiredLength(start, ending: int64): csize_t =
  var number = start
  while number <= ending:
    if isKaprekar(number): result += decimalLength(number) + 1
    inc number

proc appendDecimal(numberValue: int64, output: ptr UncheckedArray[uint8], positionValue: csize_t): csize_t =
  var digits: array[20, uint8]
  var count = 0
  var number = numberValue
  while number > 0:
    digits[count] = uint8(ord('0') + int(number mod 10))
    inc count
    number = number div 10
  if count == 0:
    digits[0] = uint8(ord('0'))
    count = 1
  result = positionValue
  while count > 0:
    dec count
    output[result] = digits[count]
    inc result

proc kaprekar_numbers_in_range*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kaprekar_numbers_in_range".} =
  if values == nil or length != 2: return -1
  let start = values[0]
  let ending = values[1]
  if start < 0 or start > ending or ending > MaxEnd: return -1
  let required = requiredLength(start, ending)
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  var number = start
  while number <= ending:
    if isKaprekar(number):
      position = appendDecimal(number, output, position)
      output[position] = 0'u8
      inc position
    inc number
  int64(position)
