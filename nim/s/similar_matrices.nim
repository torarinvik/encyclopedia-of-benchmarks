const MaxValues = 19

proc det3(m: array[9, int64]): int64 =
  m[0] * (m[4] * m[8] - m[5] * m[7]) -
    m[1] * (m[3] * m[8] - m[5] * m[6]) +
    m[2] * (m[3] * m[7] - m[4] * m[6])

proc charpoly(m: array[9, int64], n: int): tuple[a, b, c: int64] =
  var trace = 0'i64
  for i in 0 ..< n: trace += m[i * n + i]
  result.a = -trace
  if n == 2:
    result.b = m[0] * m[3] - m[1] * m[2]
  elif n == 3:
    result.b = (m[0] * m[4] - m[1] * m[3]) +
      (m[0] * m[8] - m[2] * m[6]) +
      (m[4] * m[8] - m[5] * m[7])
    result.c = -det3(m)

proc disc3(a, b, c: int64): int64 =
  a*a*b*b - 4*b*b*b - 4*a*a*a*c - 27*c*c + 18*a*b*c

proc rankSingular(m: array[9, int64], n: int): int =
  for r0 in 0 ..< n:
    for r1 in r0 + 1 ..< n:
      for c0 in 0 ..< n:
        for c1 in c0 + 1 ..< n:
          if m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0] != 0: return 2
  for i in 0 ..< n*n:
    if m[i] != 0: return 1
  0

proc shifted(m: array[9, int64], n: int, numerator, denominator: int64): array[9, int64] =
  for i in 0 ..< n*n: result[i] = denominator * m[i]
  for i in 0 ..< n: result[i*n+i] -= numerator

proc multiply(a, b: array[9, int64], n: int): array[9, int64] =
  for row in 0 ..< n:
    for col in 0 ..< n:
      for k in 0 ..< n: result[row*n+col] += a[row*n+k] * b[k*n+col]

proc areSimilar(a, b: array[9, int64], n: int): bool =
  let ca = charpoly(a, n)
  let cb = charpoly(b, n)
  if ca != cb: return false
  if n == 1: return true
  if n == 2:
    if ca.a*ca.a - 4*ca.b != 0: return true
    return rankSingular(shifted(a, n, -ca.a, 2), n) == rankSingular(shifted(b, n, -ca.a, 2), n)
  if disc3(ca.a, ca.b, ca.c) != 0: return true
  let q = ca.a*ca.a - 3*ca.b
  if q == 0:
    let da = shifted(a, n, -ca.a, 3)
    let db = shifted(b, n, -ca.a, 3)
    if rankSingular(da, n) != rankSingular(db, n): return false
    return rankSingular(multiply(da, da, n), n) == rankSingular(multiply(db, db, n), n)
  let numerator = 9*ca.c - ca.a*ca.b
  let denominator = 2*q
  rankSingular(shifted(a, n, numerator, denominator), n) ==
    rankSingular(shifted(b, n, numerator, denominator), n)

proc similar_matrices*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "similar_matrices".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 3: return -1
  let n = int(nValue)
  let matrixSize = n * n
  if int(length) != 1 + 2 * matrixSize: return -1
  var a, b: array[9, int64]
  for i in 0 ..< 2 * matrixSize:
    let value = input[1 + i]
    if value < -5 or value > 5: return -1
    if i < matrixSize: a[i] = value else: b[i - matrixSize] = value
  if areSimilar(a, b, n): 1 else: 0
