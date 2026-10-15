proc decimal_to_hex*(value: int64, output: ptr UncheckedArray[uint8],
    capacity: csize_t): int64 {.cdecl, exportc: "decimal_to_hex".} =
  if value < 0 or value > 9_007_199_254_740_991: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining >= 16:
    remaining = remaining div 16
    inc width
  if output == nil or capacity < width: return -2
  var position = width
  remaining = value
  while position > 0:
    dec position
    let digit = remaining mod 16
    if digit < 10: output[position] = uint8(ord('0') + int(digit))
    else: output[position] = uint8(ord('A') + int(digit - 10))
    remaining = remaining div 16
  int64(width)
