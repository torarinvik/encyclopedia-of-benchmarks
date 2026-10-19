const MaxDimension = 16
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]

proc two_mm*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "two_mm".} =
  if values == nil or length != 4: return InvalidResult
  for i in 0 ..< 4:
    if values[i] < 1 or values[i] > MaxDimension: return InvalidResult
  let ni = int(values[0])
  let nj = int(values[1])
  let nk = int(values[2])
  let nl = int(values[3])
  let alpha = 1.5
  let beta = 1.2
  var a, b, c, d, tmp: Matrix
  for i in 0 ..< ni:
    for k in 0 ..< nk: a[i * nk + k] = float64((i * k + 1) mod ni) / float64(ni)
  for k in 0 ..< nk:
    for j in 0 ..< nj: b[k * nj + j] = float64((k * (j + 1)) mod nj) / float64(nj)
  for j in 0 ..< nj:
    for l in 0 ..< nl: c[j * nl + l] = float64((j * (l + 3) + 1) mod nl) / float64(nl)
  for i in 0 ..< ni:
    for l in 0 ..< nl: d[i * nl + l] = float64((i * (l + 2)) mod nk) / float64(nk)
  for i in 0 ..< ni:
    for j in 0 ..< nj:
      tmp[i * nj + j] = 0.0
      for k in 0 ..< nk: tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j]
  for i in 0 ..< ni:
    for l in 0 ..< nl:
      d[i * nl + l] *= beta
      for j in 0 ..< nj: d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l]
  var checksum = 0.0
  for i in 0 ..< ni:
    for l in 0 ..< nl: checksum += d[i * nl + l]
  checksum
