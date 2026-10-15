proc powers_of10_sequence*(index: int64): int64 {.cdecl, exportc: "powers_of10_sequence".} =
  if index < 0 or index > 18: return -1
  var value = 1'i64
  var i = 0'i64
  while i < index:
    value *= 10
    i += 1
  return value
