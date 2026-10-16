proc problem137*(n: int64): int64 {.cdecl, exportc: "problem137".} =
  if n < 1 or n > 23: return -1
  var previous = 1'i64
  var current = 1'i64
  for _ in 0 ..< int(2 * n - 1):
    let next = previous + current
    previous = current
    current = next
  previous * current
