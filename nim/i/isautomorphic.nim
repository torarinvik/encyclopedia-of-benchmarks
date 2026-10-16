## Preserve the Go source's direct square-and-last-digit loop.
proc isautomorphic*(n: int64): int64 {.cdecl, exportc: "isautomorphic".} =
  const maxSafe = 3_037_000_499'i64
  if n < -maxSafe or n > maxSafe:
    return -1
  if n < 0:
    return 0

  var square = n * n
  var remaining = n
  while remaining > 0:
    if remaining mod 10 != square mod 10:
      return 0
    remaining = remaining div 10
    square = square div 10
  1
