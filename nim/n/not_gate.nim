## Return the logical complement on the Boolean 0/1 domain.
proc not_gate*(value: int64): int64 {.cdecl, exportc: "not_gate".} =
  if value == 0: 1 else: 0
