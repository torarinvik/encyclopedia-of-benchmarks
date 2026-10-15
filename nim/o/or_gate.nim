## 1 when either input is 1; otherwise 0.
proc or_gate*(left, right: uint64): int64 {.cdecl, exportc: "or_gate".} =
  int64(left | right)
