## 1 only when at least one input is 0; 0 when both are 1.
proc nand_gate*(left, right: uint64): int64 {.cdecl, exportc: "nand_gate".} =
  int64(1 - (left & right))
