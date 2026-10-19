const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]
type Vector = array[MaxDimension, float64]

proc atax*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "atax".} =
  if values == nil or length != 2: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension or values[1] < 1 or values[1] > MaxDimension:
    return InvalidResult
  let m = int(values[0])
  let n = int(values[1])
  var matrix: Matrix
  var x, y, temporary: Vector
  let fn = float64(n)
  for i in 0 ..< n: x[i] = 1.0 + float64(i) / fn
  for i in 0 ..< m:
    for j in 0 ..< n: matrix[i * n + j] = float64((i + j) mod n) / float64(5 * m)
  for i in 0 ..< n: y[i] = 0.0
  for i in 0 ..< m:
    temporary[i] = 0.0
    for j in 0 ..< n: temporary[i] = temporary[i] + matrix[i * n + j] * x[j]
    for j in 0 ..< n: y[j] = y[j] + matrix[i * n + j] * temporary[i]
  var checksum = 0.0
  for j in 0 ..< n: checksum += y[j]
  checksum
