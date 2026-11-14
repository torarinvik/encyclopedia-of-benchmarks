type Matrix = object
  prefix: array[11, array[65, int]]
  zeros: array[11, int]

proc less(matrix: Matrix, first, last, key: int): int =
  var left = first
  var right = last
  for level in 0 ..< 11:
    let zl = matrix.prefix[level][left]
    let zr = matrix.prefix[level][right]
    if (key and (1 shl (10 - level))) != 0:
      result += zr - zl
      left = matrix.zeros[level] + left - zl
      right = matrix.zeros[level] + right - zr
    else:
      left = zl
      right = zr

proc quantile(matrix: Matrix, first, last, rank: int): int =
  var left = first
  var right = last
  var k = rank
  var key = 0
  for level in 0 ..< 11:
    let zl = matrix.prefix[level][left]
    let zr = matrix.prefix[level][right]
    if k < zr - zl:
      left = zl
      right = zr
    else:
      k -= zr - zl
      key = key or (1 shl (10 - level))
      left = matrix.zeros[level] + left - zl
      right = matrix.zeros[level] + right - zr
  key - 1000

proc wavelet_matrix*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "wavelet_matrix".} =
  if input == nil or length < 2 or length > 706 or input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  if int(length) < n + 2: return -1
  for i in 0 ..< n:
    if input[1+i] < -1000 or input[1+i] > 1000: return -1
  let q = input[n+1]
  if q < 0 or q > 128 or int(length) != n + 2 + 5*int(q): return -1
  var matrix: Matrix
  var current, scratch: array[64, int]
  for i in 0 ..< n: current[i] = int(input[1+i]) + 1000
  for level in 0 ..< 11:
    let bit = 10 - level
    for i in 0 ..< n:
      matrix.prefix[level][i+1] = matrix.prefix[level][i] + int((current[i] and (1 shl bit)) == 0)
    let zeros = matrix.prefix[level][n]
    matrix.zeros[level] = zeros
    var z = 0
    var o = zeros
    for i in 0 ..< n:
      if (current[i] and (1 shl bit)) == 0:
        scratch[z] = current[i]
        inc z
      else:
        scratch[o] = current[i]
        inc o
    for i in 0 ..< n: current[i] = scratch[i]
  var total = 0'i64
  for j in 0 ..< int(q):
    let at = n + 2 + 5*j
    let op = input[at]
    let a = input[at+1]
    let b = input[at+2]
    let c = input[at+3]
    let d = input[at+4]
    var answer: int
    if op == 0:
      if a < -1000 or a > 1000 or b < -1 or b >= int64(n): return -1
      answer = matrix.less(0, int(b+1), int(a+1001)) - matrix.less(0, int(b+1), int(a+1000))
    elif op == 1:
      if a < 0 or a > b or b >= int64(n) or c < 0 or c > b-a: return -1
      answer = matrix.quantile(int(a), int(b)+1, int(c))
    elif op == 2:
      if a < 0 or a > b or b >= int64(n) or c < -1000 or c > d or d > 1000: return -1
      answer = matrix.less(int(a), int(b)+1, int(d)+1001) - matrix.less(int(a), int(b)+1, int(c)+1000)
    else: return -1
    total += int64(j+1) * (int64(answer) + 1_000_001)
  total
