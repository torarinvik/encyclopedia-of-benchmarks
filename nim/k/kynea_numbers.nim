proc kynea_numbers*(index: int64): int64 {.cdecl, exportc: "kynea_numbers".} =
  if index < 1 or index > 31: return -1
  let value = (1'i64 shl int(index)) + 1
  let square = value * value
  return square - 2
