## Return the source-compatible derangement count for n in 0..=20.
proc derangement*(n: int64): int64 {.cdecl, exportc: "derangement".} =
  if n < 0 or n > 20:
    return -1
  if n < 2:
    return 0
  if n == 2:
    return 1

  var previous = 1'i64
  var previousPrevious = 0'i64
  var i = 3'i64
  while i <= n:
    let current = (i - 1) * (previous + previousPrevious)
    previousPrevious = previous
    previous = current
    inc i
  previous
