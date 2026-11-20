proc binomial_divisibility_primality_test*(input: ptr int64, length: csize_t): int64
    {.cdecl, exportc: "binomial_divisibility_primality_test".} =
  if input == nil or length != 1: return -1
  let nValue = input[0]
  if nValue < 2 or nValue > 1000: return -1
  let n = int(nValue)

  var row: array[1001, int64]
  row[0] = 1
  var degree = 1
  while degree <= n:
    row[degree] = 1
    var index = degree - 1
    while index > 0:
      row[index] = (row[index] + row[index - 1]) mod nValue
      dec index
    inc degree
  var index = 1
  while index < n:
    if row[index] != 0: return 0
    inc index
  return 1
