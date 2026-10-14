## Write the most-significant-first binary representation of a nonnegative i64.
proc decimal_to_binary*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "decimal_to_binary".} =
  if value < 0: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining > 1:
    remaining = remaining div 2
    inc width
  if output == nil or outputCapacity < width: return -2

  var position = width
  remaining = value
  while position > 0:
    dec position
    output[position] = uint8(ord('0') + int(remaining mod 2))
    remaining = remaining div 2
  int64(width)
