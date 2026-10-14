## Iterative double factorial for the signed 64-bit benchmark contract.
proc double_factorial*(n: int64): int64 {.cdecl, exportc: "double_factorial".} =
  if n < 0 or n > 33: return -1
  var result = 1'i64
  var factor = n
  while factor > 1:
    result *= factor
    factor -= 2
  result
