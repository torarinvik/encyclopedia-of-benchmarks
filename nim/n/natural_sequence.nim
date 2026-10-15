proc natural_sequence*(index: int64): int64 {.cdecl, exportc: "natural_sequence".} =
  if index < 0 or index == high(int64): return -1
  return index + 1
