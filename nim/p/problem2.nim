proc problem2*(limit: int64): int64 {.cdecl, exportc: "problem2".} =
  if limit < 0 or limit > 4_000_000: return -1
  var previous = 1'i64
  var current = 2'i64
  var total = 0'i64
  while current < limit:
    if current mod 2 == 0:
      total += current
    let next = previous + current
    previous = current
    current = next
  total
