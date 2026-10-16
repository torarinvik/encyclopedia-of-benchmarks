const MaxLimit = 1000

proc problem120*(limit: int64): int64 {.cdecl, exportc: "problem120".} =
  if limit < 0 or limit > MaxLimit: return -1
  var total: int64 = 0
  var a: int64 = 3
  while a <= limit:
    total += 2 * a * ((a - 1) div 2)
    inc a
  total
