const MaxIndex = 230'i64

proc binomialCoefficient(n, k: int64): int64 =
  if k == 0 or k == n: return 1
  if n < 0: return 0
  return binomialCoefficient(n - 1, k) + binomialCoefficient(n - 1, k - 1)

proc binomial_sequence*(index: int64): int64 {.cdecl, exportc: "binomial_sequence".} =
  if index < 0 or index > MaxIndex: return -1
  var row = 0'i64
  var rowStart = 0'i64
  while index >= rowStart + row + 1:
    rowStart += row + 1
    row += 1
  return binomialCoefficient(row, index - rowStart)
