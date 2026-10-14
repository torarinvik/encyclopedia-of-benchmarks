## Write the octal digits of a nonnegative signed 64-bit input.
proc decimal_to_octal*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "decimal_to_octal".} =
  if value < 0: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining >= 8:
    remaining = remaining div 8
    inc width
  if output == nil or outputCapacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    output[position] = uint8(ord('0') + int(remaining mod 8))
    remaining = remaining div 8
  int64(width)
