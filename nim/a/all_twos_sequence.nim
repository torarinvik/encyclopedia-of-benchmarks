proc all_twos_sequence*(index: int64): int64 {.cdecl, exportc: "all_twos_sequence".} =
  if index < 0: return -1
  return 2
