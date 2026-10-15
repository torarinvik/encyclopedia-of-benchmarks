## Return the zero-based index of the most significant set bit.
proc highest_set_bit*(value: int64): int64 {.cdecl, exportc: "highest_set_bit".} =
  if value <= 0: return -1
  var remaining = value
  var position: int64 = -1
  while remaining > 0:
    inc position
    remaining = remaining shr 1
  position
