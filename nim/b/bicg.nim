const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]
type Vector = array[MaxDimension, float64]

proc bicg*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "bicg".} =
  if values == nil or length != 2: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension or values[1] < 1 or values[1] > MaxDimension:
    return InvalidResult
  let m = int(values[0])
  let n = int(values[1])
  var matrix: Matrix
  var p, r, s, q: Vector
  for i in 0 ..< m: p[i] = float64(i mod m) / float64(m)
  for i in 0 ..< n:
    r[i] = float64(i mod n) / float64(n)
    for j in 0 ..< m: matrix[i * m + j] = float64((i * (j + 1)) mod n) / float64(n)
  for i in 0 ..< m: s[i] = 0.0
  for i in 0 ..< n:
    q[i] = 0.0
    for j in 0 ..< m:
      s[j] = s[j] + r[i] * matrix[i * m + j]
      q[i] = q[i] + matrix[i * m + j] * p[j]
  var checksum = 0.0
  for j in 0 ..< m: checksum += s[j]
  for i in 0 ..< n: checksum += q[i]
  checksum
