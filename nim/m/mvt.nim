const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Vector = array[MaxDimension, float64]
type Matrix = array[MaxCells, float64]

proc mvt*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "mvt".} =
  if values == nil or length != 1: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension: return InvalidResult
  let n = int(values[0])
  var x1, x2, y1, y2: Vector
  var matrix: Matrix
  for i in 0 ..< n:
    x1[i] = float64(i mod n) / float64(n)
    x2[i] = float64((i + 1) mod n) / float64(n)
    y1[i] = float64((i + 3) mod n) / float64(n)
    y2[i] = float64((i + 4) mod n) / float64(n)
    for j in 0 ..< n: matrix[i * n + j] = float64((i * j) mod n) / float64(n)
  for i in 0 ..< n:
    for j in 0 ..< n: x1[i] = x1[i] + matrix[i * n + j] * y1[j]
  for i in 0 ..< n:
    for j in 0 ..< n: x2[i] = x2[i] + matrix[j * n + i] * y2[j]
  var checksum = 0.0
  for i in 0 ..< n: checksum += x1[i]
  for i in 0 ..< n: checksum += x2[i]
  checksum
