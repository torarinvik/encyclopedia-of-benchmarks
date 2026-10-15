proc count_leading_zeros*(value: int64): int64 {.cdecl, exportc: "count_leading_zeros".} =
  if value < -2147483648'i64 or value > 2147483647'i64: return -1
  if value == 0: return 32
  var mask = 1'i64 shl 31
  var count = 0'i64
  while (mask and value) == 0:
    inc count
    mask = mask shr 1
  return count
