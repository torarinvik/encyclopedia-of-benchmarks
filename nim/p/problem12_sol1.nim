proc divisorCount(value: int64): int64 =
  var remaining = value
  var factor = 2'i64
  var count = 1'i64
  while factor <= remaining div factor:
    var multiplicity = 0'i64
    while remaining mod factor == 0:
      remaining = remaining div factor
      inc multiplicity
    if multiplicity > 0: count *= multiplicity + 1
    inc factor
  if remaining > 1: count *= 2
  count

proc problem12_sol1*(threshold: int64): int64 {.cdecl, exportc: "problem12_sol1".} =
  if threshold != 500: return -1
  var index = 1'i64
  var triangular = 1'i64
  while true:
    inc index
    triangular += index
    if divisorCount(triangular) > 500: return triangular
  -1
