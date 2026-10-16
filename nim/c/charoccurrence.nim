const MaxInput = 128
const MaxOutput = 1024

proc appendDecimal(buffer: var array[MaxOutput, uint8], offset: int, value: int): int =
  var digits: array[3, uint8]
  var count = 0
  var remaining = value
  while remaining > 0:
    digits[count] = uint8(48 + remaining mod 10)
    inc count
    remaining = remaining div 10
  if count == 0:
    digits[0] = 48
    count = 1
  var position = offset
  while count > 0:
    dec count
    buffer[position] = digits[count]
    inc position
  position

## Count ASCII codepoints and emit the sorted frequency map as bytes.
proc charoccurrence*(values: ptr UncheckedArray[int64], length: csize_t,
                     output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "charoccurrence".} =
  if length > MaxInput: return -1
  if length > 0 and values.isNil: return -1
  var counts: array[128, int]
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 127: return -1
    inc counts[int(values[index])]

  var encoded: array[MaxOutput, uint8]
  var used = 0
  for codepoint in 0 ..< 128:
    if counts[codepoint] == 0: continue
    if used > 0:
      encoded[used] = uint8(ord(','))
      inc used
    used = appendDecimal(encoded, used, codepoint)
    encoded[used] = uint8(ord('='))
    inc used
    used = appendDecimal(encoded, used, counts[codepoint])
  if csize_t(used) > capacity: return -2
  if used > 0 and output.isNil: return -2
  for index in 0 ..< used: output[index] = encoded[index]
  int64(used)
