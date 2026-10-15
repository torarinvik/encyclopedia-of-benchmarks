proc all_ones_sequence*(index: int64): int64 {.cdecl, exportc: "all_ones_sequence".} =
  if index < 0: return -1
  return 1
