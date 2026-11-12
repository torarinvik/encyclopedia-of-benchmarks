import std/math

const MaxN = 32
const MaxCoarse = 16
const MaxSteps = 12
const MaxMicro = 1_000_000_000'i64
const Scale = 1_000_000.0

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc matvec(v: ptr UncheckedArray[int64], n, nnz: int,
            x: var array[MaxN, float64], y: var array[MaxN, float64]) =
  let col = 4 + n
  let val = col + nnz
  for row in 0 ..< n:
    var total = 0.0
    for edge in int(v[3 + row]) ..< int(v[4 + row]):
      total += float64(v[val + edge]) / Scale * x[int(v[col + edge])]
    y[row] = total

proc coarseSolve(v: ptr UncheckedArray[int64], n, nnz: int,
                 rhs: var array[MaxCoarse, float64],
                 solution: var array[MaxCoarse, float64]): bool =
  let cn = (n + 1) div 2
  let col = 4 + n
  let val = col + nnz
  var a: array[MaxCoarse * MaxCoarse, float64]
  var lower: array[MaxCoarse * MaxCoarse, float64]
  for row in 0 ..< n:
    for edge in int(v[3 + row]) ..< int(v[4 + row]):
      a[(row div 2) * MaxCoarse + int(v[col + edge]) div 2] += float64(v[val + edge]) / Scale
  for i in 0 ..< cn:
    for j in 0 .. i:
      var value = a[i * MaxCoarse + j]
      for k in 0 ..< j: value -= lower[i * MaxCoarse + k] * lower[j * MaxCoarse + k]
      if i == j:
        if value <= 0.0: return false
        lower[i * MaxCoarse + j] = sqrt(value)
      else:
        lower[i * MaxCoarse + j] = value / lower[j * MaxCoarse + j]
  var y: array[MaxCoarse, float64]
  for i in 0 ..< cn:
    var value = rhs[i]
    for j in 0 ..< i: value -= lower[i * MaxCoarse + j] * y[j]
    y[i] = value / lower[i * MaxCoarse + i]
  for ii in countdown(cn - 1, 0):
    var value = y[ii]
    for j in ii + 1 ..< cn: value -= lower[j * MaxCoarse + ii] * solution[j]
    solution[ii] = value / lower[ii * MaxCoarse + ii]
  true

proc precondition(v: ptr UncheckedArray[int64], n, nnz: int,
                  diagonal: var array[MaxN, float64], r: var array[MaxN, float64],
                  z: var array[MaxN, float64]): bool =
  let col = 4 + n
  let val = col + nnz
  var pre, product, middle, postResidual, post: array[MaxN, float64]
  for row in 0 ..< n:
    var value = r[row]
    for edge in int(v[3 + row]) ..< int(v[4 + row]):
      let c = int(v[col + edge])
      if c < row: value -= float64(v[val + edge]) / Scale * pre[c]
    pre[row] = value / diagonal[row]
  matvec(v, n, nnz, pre, product)
  var coarseRhs, coarseX: array[MaxCoarse, float64]
  for row in 0 ..< n: coarseRhs[row div 2] += r[row] - product[row]
  if not coarseSolve(v, n, nnz, coarseRhs, coarseX): return false
  for row in 0 ..< n: middle[row] = pre[row] + coarseX[row div 2]
  matvec(v, n, nnz, middle, product)
  for row in 0 ..< n: postResidual[row] = r[row] - product[row]
  for ii in countdown(n - 1, 0):
    var value = postResidual[ii]
    for edge in int(v[3 + ii]) ..< int(v[4 + ii]):
      let c = int(v[col + edge])
      if c > ii: value -= float64(v[val + edge]) / Scale * post[c]
    post[ii] = value / diagonal[ii]
  for row in 0 ..< n: z[row] = middle[row] + post[row]
  true

proc validate(v: ptr UncheckedArray[int64], length: int,
              n, steps, nnz: var int, diagonal: var array[MaxN, float64]): bool =
  if v.isNil or length < 8 or length > 452: return false
  if v[0] < 1 or v[0] > int64(MaxN) or v[1] < 1 or v[1] > int64(MaxSteps) or
      v[1] > v[0] or v[2] < v[0] or v[2] > 6'i64 * v[0]: return false
  n = int(v[0]); steps = int(v[1]); nnz = int(v[2])
  if length != 4 + 2 * n + 2 * nnz: return false
  let col = 4 + n
  let val = col + nnz
  let rhs = val + nnz
  if v[3] != 0 or v[3 + n] != int64(nnz): return false
  for row in 0 ..< n:
    let begin = int(v[3 + row]); let finish = int(v[4 + row])
    if begin < 0 or begin >= finish or finish > nnz or finish - begin > 6: return false
    var d = 0'i64; var off = 0'i64; var previous = -1'i64
    for edge in begin ..< finish:
      let c = v[col + edge]; let a = v[val + edge]
      if c < 0 or c >= int64(n) or c <= previous or a == 0 or a < -MaxMicro or a > MaxMicro: return false
      previous = c
      if c == int64(row): d = a else: off += abs(a)
    if d <= 0 or d <= off or v[rhs + row] < -MaxMicro or v[rhs + row] > MaxMicro: return false
    diagonal[row] = float64(d) / Scale
  for row in 0 ..< n:
    for edge in int(v[3 + row]) ..< int(v[4 + row]):
      let c = int(v[col + edge])
      var found = false
      for reverse in int(v[3 + c]) ..< int(v[4 + c]):
        if v[col + reverse] == int64(row) and v[val + reverse] == v[val + edge]: found = true; break
      if not found: return false
  true

proc hpcg_profile*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hpcg_profile".} =
  var n, steps, nnz: int
  var diagonal: array[MaxN, float64]
  if not validate(input, int(length), n, steps, nnz, diagonal): return -1
  let outputBytes = 8 * (n + 1)
  if output.isNil or int(capacity) < outputBytes: return -2
  let rhs = 4 + n + 2 * nnz
  var b, x, r, z, p, q, ax: array[MaxN, float64]
  var b2 = 0.0
  for i in 0 ..< n: b[i] = float64(input[rhs + i]) / Scale; r[i] = b[i]; b2 += b[i] * b[i]
  if b2 > 0.0:
    if not precondition(input, n, nnz, diagonal, r, z): return -1
    p = z
    var rho = 0.0
    for i in 0 ..< n: rho += r[i] * z[i]
    if rho <= 0.0: return -1
    for _ in 0 ..< steps:
      matvec(input, n, nnz, p, q)
      var curvature = 0.0
      for i in 0 ..< n: curvature += p[i] * q[i]
      if curvature <= 0.0: return -1
      let alpha = rho / curvature
      for i in 0 ..< n: x[i] += alpha * p[i]; r[i] -= alpha * q[i]
      var r2 = 0.0
      for i in 0 ..< n: r2 += r[i] * r[i]
      if r2 <= b2 * 1.0e-28: break
      var nextZ: array[MaxN, float64]
      if not precondition(input, n, nnz, diagonal, r, nextZ): return -1
      var nextRho = 0.0
      for i in 0 ..< n: nextRho += r[i] * nextZ[i]
      if nextRho <= 0.0: return -1
      let beta = nextRho / rho
      for i in 0 ..< n: z[i] = nextZ[i]; p[i] = z[i] + beta * p[i]
      rho = nextRho
  matvec(input, n, nnz, x, ax)
  var residual2 = 0.0
  for i in 0 ..< n: let e = b[i] - ax[i]; residual2 += e * e; writeF64Le(output, 8 * i, x[i])
  writeF64Le(output, 8 * n, sqrt(residual2))
  int64(outputBytes)
