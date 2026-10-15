proc all_threes_sequence*(index: int64): int64 {.cdecl, exportc: "all_threes_sequence".} =
  if index < 0: return -1
  return 3
