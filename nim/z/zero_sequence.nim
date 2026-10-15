proc zero_sequence*(index: int64): int64 {.cdecl, exportc: "zero_sequence".} =
  if index < 0: return -1
  return 0
