## Encode prime factors in ascending order, retaining multiplicity.
proc decimalLength(value: int64): csize_t =
  var remaining = value
  var length = csize_t(1)
  while remaining >= 10:
    remaining = remaining div 10
    inc length
  length

proc requiredLength(value: int64): csize_t =
  var length = csize_t(0)
  var count = csize_t(0)
  var remaining = value
  var divisor = 2'i64
  while divisor <= remaining div divisor:
    while remaining mod divisor == 0:
      length += decimalLength(divisor)
      if count > 0: inc length
      inc count
      remaining = remaining div divisor
    inc divisor
  if remaining > 1:
    length += decimalLength(remaining)
    if count > 0: inc length
  length

proc appendDecimal(value: int64, output: ptr UncheckedArray[uint8],
    positionValue: csize_t): csize_t =
  var digits: array[10, uint8]
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

proc prime_factors*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "prime_factors".} =
  if value < 1 or value > 2147483647: return -1
  let required = requiredLength(value)
  if output == nil or outputCapacity < required: return -2
  var position = csize_t(0)
  var count = csize_t(0)
  var remaining = value
  var divisor = 2'i64
  while divisor <= remaining div divisor:
    while remaining mod divisor == 0:
      if count > 0:
        output[position] = uint8(',')
        inc position
      position = appendDecimal(divisor, output, position)
      inc count
      remaining = remaining div divisor
    inc divisor
  if remaining > 1:
    if count > 0:
      output[position] = uint8(',')
      inc position
    position = appendDecimal(remaining, output, position)
  int64(position)
