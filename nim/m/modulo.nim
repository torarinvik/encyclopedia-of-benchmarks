## Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
proc modulo*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "modulo".} =
  if length != 2 or values == nil: return -1
  let a = values[0]
  let b = values[1]
  if a < 0'i64 or a > 4_294_967_295'i64 or b < 1'i64 or b > 4_294_967_295'i64: return -1
  a mod b
