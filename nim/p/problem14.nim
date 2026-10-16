proc collatzLength(start: uint64): uint64 =
  var current = start
  var length = 1'u64
  while current != 1'u64:
    if length >= 10_000'u64: return 0'u64
    if current mod 2'u64 == 0'u64:
      current = current div 2'u64
    else:
      if current > 6_148_914_691_236_517_204'u64: return 0'u64
      current = 3'u64 * current + 1'u64
    inc length
  length

proc problem14*(limit: int64): int64 {.cdecl, exportc: "problem14".} =
  if limit < 1 or limit > 1_000_000: return -1
  var bestStart = 1'u64
  var bestLength = 1'u64
  var start = 2'u64
  while start <= uint64(limit):
    let length = collatzLength(start)
    if length == 0'u64: return -1
    if length > bestLength:
      bestStart = start
      bestLength = length
    inc start
  int64(bestStart)
