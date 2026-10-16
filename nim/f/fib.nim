proc fib*(n: int64): int64 {.cdecl, exportc: "fib".} =
  if n < 0 or n > 90: return -1
  var previous = 1'i64
  var current = 2'i64
  for i in 0'i64 ..< n:
    let next = previous + current
    previous = current
    current = next
  return previous
