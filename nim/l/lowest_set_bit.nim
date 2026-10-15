## Return the isolated least significant set bit.
proc lowest_set_bit*(value: int64): int64 {.cdecl, exportc: "lowest_set_bit".} =
  if value < 0 or value > 2_147_483_647: return -1
  value and -value
