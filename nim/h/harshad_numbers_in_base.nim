const MaxLimit = 10000'i64

proc digitSum(number, base: int64): int64 =
  var remaining = number
  while remaining > 0:
    result += remaining mod base
    remaining = remaining div base

proc baseLength(number, base: int64): csize_t =
  var remaining = number
  while remaining > 0:
    inc result
    remaining = remaining div base

proc requiredLength(limit, base: int64): csize_t =
  var number = 1'i64
  while number < limit:
    if number mod digitSum(number, base) == 0:
      result += baseLength(number, base) + 1
    inc number

proc digitByte(digit: int64): uint8 =
  if digit < 10: return uint8(ord('0') + int(digit))
  uint8(ord('A') + int(digit - 10))

proc appendBase(numberValue, base: int64, output: ptr UncheckedArray[uint8],
    positionValue: csize_t): csize_t =
  var digits: array[64, uint8]
  var count = 0
  var remaining = numberValue
  while remaining > 0:
    digits[count] = digitByte(remaining mod base)
    inc count
    remaining = remaining div base
  result = positionValue
  while count > 0:
    dec count
    output[result] = digits[count]
    inc result

proc harshad_numbers_in_base*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "harshad_numbers_in_base".} =
  if values == nil or length != 2: return -1
  let limit = values[0]
  let base = values[1]
  if limit > MaxLimit or base < 2 or base > 36: return -1
  let required = requiredLength(limit, base)
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  var number = 1'i64
  while number < limit:
    if number mod digitSum(number, base) == 0:
      position = appendBase(number, base, output, position)
      output[position] = 0'u8
      inc position
    inc number
  int64(position)
