## Convert a uint16 value to lowercase digits in a base from 2 through 16.
const MaxValue = 65535
const Symbols = "0123456789abcdef"

proc int_to_string*(packed: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "int_to_string".} =
  if packed < 0: return -1
  let value = packed div 15
  let base = packed mod 15 + 2
  if value > MaxValue: return -1
  var digits: array[16, uint8]
  var count = 0
  var remaining = value
  while true:
    digits[count] = uint8(ord(Symbols[int(remaining mod base)]))
    inc count
    remaining = remaining div base
    if remaining == 0: break
  let required = count + 1
  if output.isNil or outputCapacity < csize_t(required): return -2
  for index in 0 ..< count: output[index] = digits[count - index - 1]
  output[count] = 0
  int64(required)
