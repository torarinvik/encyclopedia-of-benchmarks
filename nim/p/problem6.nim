proc problem6*(limit: int64): int64 {.cdecl, exportc: "problem6".} =
  if limit < 0 or limit > 100: return -1
  var total = 0'i64
  var sumOfSquares = 0'i64
  for value in 1'i64..limit:
    total += value
    sumOfSquares += value * value
  total * total - sumOfSquares
