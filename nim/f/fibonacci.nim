## Iterative Fibonacci for the shared signed 64-bit benchmark contract.
proc fibonacci*(n: int64): int64 {.cdecl, exportc: "fibonacci".} =
  if n < 0 or n > 92:
    return -1
  if n == 0:
    return 0

  var previous = 0'i64
  var current = 1'i64
  var index = 1'i64
  while index < n:
    let next = previous + current
    previous = current
    current = next
    inc index
  return current
