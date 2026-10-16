proc problem1*(limit: int64): int64 {.cdecl, exportc: "problem1".} =
  if limit < 0 or limit > 100_000: return -1
  var total = 0'i64
  var value = 1'i64
  while value < limit:
    if value mod 3 == 0 or value mod 5 == 0:
      total += value
    inc value
  total
