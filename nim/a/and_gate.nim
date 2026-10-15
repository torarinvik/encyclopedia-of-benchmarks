## Two-input Boolean AND over the benchmark's 0/1 domain.
proc and_gate*(left, right: uint64): int64 {.cdecl, exportc: "and_gate".} =
  int64(left and right)
