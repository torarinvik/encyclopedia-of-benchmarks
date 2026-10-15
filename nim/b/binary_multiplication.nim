## Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
proc binary_multiplication*(a, b: uint64): int64 {.cdecl, exportc: "binary_multiplication".} =
  var multiplicand = a
  var multiplier = b
  var accumulated = 0'u64
  while multiplier > 0:
    if (multiplier and 1'u64) != 0:
      accumulated += multiplicand
    multiplicand += multiplicand
    multiplier = multiplier shr 1
  int64(accumulated)
