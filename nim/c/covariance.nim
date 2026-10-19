const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]
type Vector = array[MaxDimension, float64]

proc covariance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "covariance".} =
  if values == nil or length != 2: return InvalidResult
  if values[0] < 2 or values[0] > MaxDimension or values[1] < 1 or values[1] > MaxDimension:
    return InvalidResult
  let n = int(values[0])
  let m = int(values[1])
  let floatN = float64(n)
  var data, cov: Matrix
  var mean: Vector
  for i in 0 ..< n:
    for j in 0 ..< m: data[i * m + j] = (float64(i) * float64(j)) / float64(m)
  for j in 0 ..< m:
    mean[j] = 0.0
    for i in 0 ..< n: mean[j] += data[i * m + j]
    mean[j] /= floatN
  for i in 0 ..< n:
    for j in 0 ..< m: data[i * m + j] -= mean[j]
  for i in 0 ..< m:
    for j in i ..< m:
      cov[i * m + j] = 0.0
      for k in 0 ..< n: cov[i * m + j] += data[k * m + i] * data[k * m + j]
      cov[i * m + j] /= floatN - 1.0
      cov[j * m + i] = cov[i * m + j]
  var checksum = 0.0
  for i in 0 ..< m:
    for j in 0 ..< m: checksum += cov[i * m + j]
  checksum
