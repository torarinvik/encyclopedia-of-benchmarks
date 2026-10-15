## Return the one-based position of the least significant set bit.
proc rightmost_set_bit*(value: int64): int64 {.cdecl, exportc: "rightmost_set_bit".} =
  if value <= 0 or value > 2_147_483_647: return -1
  var lowest = uint32(value) and (0'u32 - uint32(value))
  result = 1
  while (lowest and 1'u32) == 0'u32:
    lowest = lowest shr 1
    inc result
