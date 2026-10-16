proc nimply_gate*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "nimply_gate".} =
  if values == nil or length != 2: return -1
  let a = values[0]
  let b = values[1]
  if (a != 0 and a != 1) or (b != 0 and b != 1): return -1
  if a == 1 and b == 0: return 1
  0
