const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]

proc gemm*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gemm".} =
  if values == nil or length != 3: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension or values[1] < 1 or values[1] > MaxDimension or
     values[2] < 1 or values[2] > MaxDimension: return InvalidResult
  let ni = int(values[0])
  let nj = int(values[1])
  let nk = int(values[2])
  let alpha = 1.5
  let beta = 1.2
  var c, a, b: Matrix
  for i in 0 ..< ni:
    for j in 0 ..< nj: c[i * nj + j] = float64((i * j + 1) mod ni) / float64(ni)
  for i in 0 ..< ni:
    for k in 0 ..< nk: a[i * nk + k] = float64((i * (k + 1)) mod nk) / float64(nk)
  for k in 0 ..< nk:
    for j in 0 ..< nj: b[k * nj + j] = float64((k * (j + 2)) mod nj) / float64(nj)
  for i in 0 ..< ni:
    for j in 0 ..< nj: c[i * nj + j] *= beta
    for k in 0 ..< nk:
      for j in 0 ..< nj: c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]
  var checksum = 0.0
  for i in 0 ..< ni:
    for j in 0 ..< nj: checksum += c[i * nj + j]
  checksum
