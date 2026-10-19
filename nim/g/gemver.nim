const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]
type Vector = array[MaxDimension, float64]

proc gemver*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gemver".} =
  if values == nil or length != 1: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension: return InvalidResult
  let n = int(values[0])
  let fn = float64(n)
  let alpha = 1.5
  let beta = 1.2
  var a: Matrix
  var u1, v1, u2, v2, w, x, y, z: Vector
  for i in 0 ..< n:
    u1[i] = float64(i)
    u2[i] = (float64(i + 1) / fn) / 2.0
    v1[i] = (float64(i + 1) / fn) / 4.0
    v2[i] = (float64(i + 1) / fn) / 6.0
    y[i] = (float64(i + 1) / fn) / 8.0
    z[i] = (float64(i + 1) / fn) / 9.0
    for j in 0 ..< n: a[i * n + j] = float64((i * j) mod n) / fn
  for i in 0 ..< n:
    for j in 0 ..< n:
      a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j]
  for i in 0 ..< n:
    for j in 0 ..< n: x[i] = x[i] + beta * a[j * n + i] * y[j]
  for i in 0 ..< n: x[i] = x[i] + z[i]
  for i in 0 ..< n:
    for j in 0 ..< n: w[i] = w[i] + alpha * a[i * n + j] * x[j]
  var checksum = 0.0
  for i in 0 ..< n: checksum += w[i]
  checksum
