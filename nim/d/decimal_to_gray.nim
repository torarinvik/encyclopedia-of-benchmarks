## Write the minimal-width ASCII binary form of n xor (n shr 1).
proc decimal_to_gray*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "decimal_to_gray".} =
  if value < 0: return -1
  let gray = value xor (value shr 1)
  var width = csize_t(1)
  var remaining = gray
  while remaining > 1:
    remaining = remaining div 2
    inc width
  if output == nil or outputCapacity < width: return -2

  var position = width
  remaining = gray
  while position > 0:
    dec position
    output[position] = uint8(ord('0') + int(remaining mod 2))
    remaining = remaining div 2
  int64(width)
