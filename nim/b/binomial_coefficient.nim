## Calculate C(n, k) by updating one row of Pascal's triangle.
proc binomial_coefficient*(n, k: uint64): int64 {.cdecl, exportc: "binomial_coefficient".} =
  if n > 66: return -1
  if k > n: return 0
  if k == 0: return 1
  var coefficients: array[67, int64]
  coefficients[0] = 1
  var row = 1'u64
  while row <= n:
    var column = min(row, k)
    while column > 0:
      coefficients[int(column)] += coefficients[int(column - 1)]
      dec column
    inc row
  coefficients[int(k)]
