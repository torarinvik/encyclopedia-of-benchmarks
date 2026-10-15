proc clear_leftmost_set_bit*(value: int64): int64 {.cdecl, exportc: "clear_leftmost_set_bit".} =
  if value < 0 or value > 2147483647'i64: return -1
  if value == 0: return 0
  var temp = value
  var position = 0'i64
  while temp > 0:
    temp = temp shr 1
    inc position
  let mask = not (1'i64 shl (position - 1))
  return value and mask
