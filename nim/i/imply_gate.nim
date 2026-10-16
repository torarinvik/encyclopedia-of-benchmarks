proc imply_gate*(left, right: uint64): int64 {.cdecl, exportc: "imply_gate".} =
  if left > 1 or right > 1: return -1
  if left == 0 or right == 1: return 1
  0
