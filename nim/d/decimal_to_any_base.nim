## Convert a nonnegative signed 64-bit value to base 2 through 36.
proc decimal_to_any_base*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "decimal_to_any_base".} =
  if input == nil or length != 2: return -1
  let value = input[0]
  let base = input[1]
  if value < 0 or base < 2 or base > 36: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining >= base:
    remaining = remaining div base
    inc width
  if output == nil or outputCapacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    let digit = remaining mod base
    if digit < 10:
      output[position] = uint8(ord('0') + int(digit))
    else:
      output[position] = uint8(ord('A') + int(digit) - 10)
    remaining = remaining div base
  int64(width)
