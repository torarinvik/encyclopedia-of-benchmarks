proc lucas_series*(n: int64): int64 {.cdecl, exportc: "lucas_series".} =
  if n < 0 or n > 90: return -1
  if n == 0: return 2
  var previous = 2'i64
  var current = 1'i64
  var index = 2'i64
  while index <= n:
    let next = previous + current
    previous = current
    current = next
    inc index
  current
