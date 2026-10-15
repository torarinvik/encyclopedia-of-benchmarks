proc cubes_sequence*(index: int64): int64 {.cdecl, exportc: "cubes_sequence".} =
  if index < 0 or index > 2097151: return -1
  return index * index * index
