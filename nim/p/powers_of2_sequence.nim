## Return a term from the bounded powers-of-two sequence.
proc powers_of2_sequence*(index: int64): int64 {.cdecl, exportc: "powers_of2_sequence".} =
  if index < 0 or index > 62: return -1
  var value = 1'i64
  var step = 0'i64
  while step < index:
    value *= 2
    step += 1
  return value
