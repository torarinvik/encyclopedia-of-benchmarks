const MaxValues = 256
const MaxParseableInputLength = MaxValues + 2
const MaxOutputBytes = 3836
const I32MinValue = -2147483648'i64
const I32MaxValue = 2147483647'i64

proc appendDecimal(buffer: var array[MaxOutputBytes, uint8], position: var int, value: int64) =
  var digits: array[10, uint8]
  var count = 0
  var magnitude: uint64
  if value < 0:
    buffer[position] = uint8(45)
    inc position
    magnitude = uint64(-value)
  else:
    magnitude = uint64(value)
  while true:
    digits[count] = uint8(48 + magnitude mod 10)
    inc count
    magnitude = magnitude div 10
    if magnitude == 0: break
  while count > 0:
    dec count
    buffer[position] = digits[count]
    inc position

proc print_reverse*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "print_reverse".} =
  if length > MaxParseableInputLength.csize_t or length > MaxValues.csize_t: return -1
  if length > 0 and values.isNil: return -1
  for index in 0 ..< length.int:
    let value = values[index]
    if value < I32MinValue or value > I32MaxValue: return -1

  var encoded: array[MaxOutputBytes, uint8]
  var written = 0
  var remaining = length.int
  while remaining > 0:
    dec remaining
    if written > 0:
      encoded[written] = uint8(32)
      encoded[written + 1] = uint8(60)
      encoded[written + 2] = uint8(45)
      encoded[written + 3] = uint8(32)
      written += 4
    appendDecimal(encoded, written, values[remaining])

  if output.isNil or outputCapacity < written.csize_t: return -2
  for index in 0 ..< written:
    output[index] = encoded[index]
  written.int64
