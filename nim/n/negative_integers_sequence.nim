proc negative_integers_sequence*(index: int64): int64 {.cdecl, exportc: "negative_integers_sequence".} =
  if index < 0: return 0
  return -index - 1
