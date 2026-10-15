## 1 when the inputs are equal; otherwise 0.
proc xnor_gate*(left, right: uint64): int64 {.cdecl, exportc: "xnor_gate".} =
  int64(1 - (left ^ right))
