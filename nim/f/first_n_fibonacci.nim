## Emit the first n Fibonacci terms as decimal NUL-terminated values.
const MinCount = 3'i64
const MaxCount = 79'i64

proc decimalLength(numberValue: int64): csize_t =
  var number = numberValue
  result = 1
  while number >= 10:
    number = number div 10
    inc result

proc requiredLength(count: int64): csize_t =
  var previous = 0'i64
  var current = 1'i64
  var index = 0'i64
  while index < count:
    var value: int64
    if index == 0: value = 0
    elif index == 1: value = 1
    else:
      value = previous + current
      previous = current
      current = value
    result += decimalLength(value) + 1
    inc index

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

proc first_n_fibonacci*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "first_n_fibonacci".} =
  if values == nil or length != 1: return -1
  let count = values[0]
  if count < MinCount or count > MaxCount: return -1
  let required = requiredLength(count)
  if output == nil or outputCapacity < required: return -2
  var previous = 0'i64
  var current = 1'i64
  var index = 0'i64
  var position = csize_t(0)
  while index < count:
    var value: int64
    if index == 0: value = 0
    elif index == 1: value = 1
    else:
      value = previous + current
      previous = current
      current = value
    position = appendDecimal(value, output, position)
    output[position] = 0'u8
    inc position
    inc index
  int64(position)
