import std/math

const maxDimension = 64
const maxCells = maxDimension * maxDimension
const invalidResult = -1e300

type Matrix = array[maxCells, float64]

proc polybench_cholesky*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "polybench_cholesky".} =
  if values == nil or length != 1: return invalidResult
  if values[0] < 1 or values[0] > maxDimension: return invalidResult
  let n = int(values[0])
  var a, product: Matrix
  for i in 0 ..< n:
    for j in 0 .. i: a[i * n + j] = float64(-(j mod n)) / float64(n) + 1.0
    for j in i + 1 ..< n: a[i * n + j] = 0.0
    a[i * n + i] = 1.0
  for r in 0 ..< n:
    for s in 0 ..< n: product[r * n + s] = 0.0
  for t in 0 ..< n:
    for r in 0 ..< n:
      for s in 0 ..< n:
        product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
  for r in 0 ..< n:
    for s in 0 ..< n: a[r * n + s] = product[r * n + s]
  for i in 0 ..< n:
    for j in 0 ..< i:
      for k in 0 ..< j: a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k]
      a[i * n + j] = a[i * n + j] / a[j * n + j]
    for k in 0 ..< i: a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k]
    a[i * n + i] = sqrt(a[i * n + i])
  var result = 0.0
  for i in 0 ..< n:
    for j in 0 .. i: result += a[i * n + j]
  result
