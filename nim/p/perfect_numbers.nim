proc perfect_numbers*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "perfect_numbers".} =
  if v.isNil or n != 1 or v[0] < 0 or v[0] > 1_000_000_000: return -1
  let x = v[0]
  if x <= 1: return 0
  var total = 1'i64
  var d = 2'i64
  while d <= x div d:
    if x mod d == 0:
      total += d
      if d != x div d: total += x div d
    inc d
  int64(total == x)

