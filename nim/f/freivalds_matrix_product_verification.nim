const MaxN = 8
const MaxInput = 259

proc freivalds_matrix_product_verification*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc:"freivalds_matrix_product_verification".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let rounds0 = input[1]
  if n0 < 1 or n0 > 8 or rounds0 < 1 or rounds0 > 8: return -1
  let n = int(n0)
  let rounds = int(rounds0)
  let matrixWords = n * n
  if int(length) != 2 + 3 * matrixWords + rounds * n: return -1
  for word in 2 ..< 2 + 3 * matrixWords:
    if input[word] < -3 or input[word] > 3: return -1
  let signsOffset = 2 + 3 * matrixWords
  for word in signsOffset ..< int(length):
    if input[word] != -1 and input[word] != 1: return -1

  var bx, abx, cx: array[MaxN, int64]
  for round in 0 ..< rounds:
    for row in 0 ..< n:
      var sum = 0'i64
      for col in 0 ..< n:
        sum += input[2 + matrixWords + row * n + col] * input[signsOffset + round * n + col]
      bx[row] = sum
    for row in 0 ..< n:
      var left, right = 0'i64
      for col in 0 ..< n:
        left += input[2 + row * n + col] * bx[col]
        right += input[2 + 2 * matrixWords + row * n + col] * input[signsOffset + round * n + col]
      abx[row] = left
      cx[row] = right
    for row in 0 ..< n:
      if abx[row] != cx[row]: return 0
  1
