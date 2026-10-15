## List all positive divisors in ascending decimal order.
proc decimalLength(value: int64): csize_t =
  var remaining = value
  var length = csize_t(1)
  while remaining >= 10:
    remaining = remaining div 10
    inc length
  length

proc appendDecimal(value: int64, output: ptr UncheckedArray[uint8],
    positionValue: csize_t): csize_t =
  var digits: array[3, uint8]
  var count = 0
  var remaining = value
  while remaining > 0:
    digits[count] = uint8(remaining mod 10)
    inc count
    remaining = remaining div 10
  var position = positionValue
  while count > 0:
    dec count
    output[position] = uint8('0') + digits[count]
    inc position
  position

proc factors*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "factors".} =
  if value < 1 or value > 256: return -1
  var required = csize_t(0)
  var count = csize_t(0)
  for divisor in 1'i64 .. value:
    if value mod divisor == 0:
      required += decimalLength(divisor)
      if count > 0: inc required
      inc count
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  count = 0
  for divisor in 1'i64 .. value:
    if value mod divisor == 0:
      if count > 0:
        output[position] = uint8(',')
        inc position
      position = appendDecimal(divisor, output, position)
      inc count
  int64(position)
