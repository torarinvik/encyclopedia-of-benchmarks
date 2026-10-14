## Iterative factorial for the shared signed 64-bit benchmark contract.
proc factorial*(n: int64): int64 {.cdecl, exportc: "factorial".} =
  if n < 0 or n > 20:
    return -1

  var product = 1'i64
  var factor = 2'i64
  while factor <= n:
    product *= factor
    inc factor
  return product
