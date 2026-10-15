## Return J(n) for the bounded signed-64-bit Jacobsthal index.
proc jacobsthal_number*(n: int64): int64 {.cdecl, exportc: "jacobsthal_number".} =
  if n < 0 or n > 64: return -1
  if n == 0: return 0
  var previous = 0'i64
  var current = 1'i64
  var index = 2'i64
  while index <= n:
    let nextValue = current + 2 * previous
    previous = current
    current = nextValue
    index += 1
  return current
