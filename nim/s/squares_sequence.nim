const MaxIndex = 3_037_000_499'i64

proc squares_sequence*(index: int64): int64 {.cdecl, exportc: "squares_sequence".} =
  if index < 0 or index > MaxIndex: return -1
  return index * index
