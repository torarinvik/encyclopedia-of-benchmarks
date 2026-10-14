## Return 1 for even and 0 for odd signed 64-bit integers.
proc is_even*(value: int64): int64 {.cdecl, exportc: "is_even".} =
  if value mod 2 == 0:
    return 1
  return 0
