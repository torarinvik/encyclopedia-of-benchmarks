## 1 when the inputs differ; otherwise 0.
proc xor_gate*(left, right: uint64): int64 {.cdecl, exportc: "xor_gate".} =
  int64(left ^ right)
