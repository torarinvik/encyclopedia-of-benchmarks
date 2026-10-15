## Tabulated Fibonacci for the bounded signed 64-bit benchmark contract.
proc fibonacci_dp*(n: int64): int64 {.cdecl, exportc: "fibonacci_dp".} =
  if n < 0 or n > 46:
    return -1

  var table: array[47, int64]
  table[0] = 0
  table[1] = 1
  var index = 2'i64
  while index <= n:
    table[index] = table[index - 1] + table[index - 2]
    inc index
  return table[n]
