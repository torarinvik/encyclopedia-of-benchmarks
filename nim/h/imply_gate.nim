## Two-input Boolean implication over the benchmark's 0/1 domain.
proc imply_gate*(left, right: uint64): int64 {.cdecl, exportc: "imply_gate".} =
  if left == 0 or right == 1: 1 else: 0
