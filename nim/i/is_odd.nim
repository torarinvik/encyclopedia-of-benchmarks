## Return 1 for odd and 0 for even signed 64-bit integers.
proc is_odd*(value: int64): int64 {.cdecl, exportc: "is_odd".} =
  if value mod 2 != 0:
    return 1
  return 0
