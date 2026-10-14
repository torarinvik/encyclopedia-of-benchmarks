## Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
proc decimal_to_hexadecimal*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "decimal_to_hexadecimal".} =
  if value < 0: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining >= 16:
    remaining = remaining div 16
    inc width
  if output == nil or outputCapacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    let digit = remaining mod 16
    if digit < 10: output[position] = uint8(ord('0') + int(digit))
    else: output[position] = uint8(ord('a') + int(digit - 10))
    remaining = remaining div 16
  int64(width)
