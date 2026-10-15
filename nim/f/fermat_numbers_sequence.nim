proc fermat_numbers_sequence*(index: int64): int64 {.cdecl, exportc: "fermat_numbers_sequence".} =
  if index < 0 or index > 5: return -1
  var value = 2'i64
  for _ in 0 ..< index: value *= value
  return value + 1
