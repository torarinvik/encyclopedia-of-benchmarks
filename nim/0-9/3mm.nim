const MaxDimension = 16
const MaxCells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Matrix = array[MaxCells, float64]

proc three_mm*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "three_mm".} =
  if values == nil or length != 5: return InvalidResult
  for i in 0 ..< 5:
    if values[i] < 1 or values[i] > MaxDimension: return InvalidResult
  let ni = int(values[0])
  let nj = int(values[1])
  let nk = int(values[2])
  let nl = int(values[3])
  let nm = int(values[4])
  var a, b, c, d, e, f, g: Matrix
  for i in 0 ..< ni:
    for k in 0 ..< nk: a[i * nk + k] = float64((i * k + 1) mod ni) / float64(5 * ni)
  for k in 0 ..< nk:
    for j in 0 ..< nj: b[k * nj + j] = float64((k * (j + 1) + 2) mod nj) / float64(5 * nj)
  for i in 0 ..< nj:
    for j in 0 ..< nm: c[i * nm + j] = float64((i * (j + 3)) mod nl) / float64(5 * nl)
  for i in 0 ..< nm:
    for j in 0 ..< nl: d[i * nl + j] = float64((i * (j + 2) + 2) mod nk) / float64(5 * nk)
  for i in 0 ..< ni:
    for j in 0 ..< nj:
      e[i * nj + j] = 0.0
      for k in 0 ..< nk: e[i * nj + j] += a[i * nk + k] * b[k * nj + j]
  for i in 0 ..< nj:
    for j in 0 ..< nl:
      f[i * nl + j] = 0.0
      for k in 0 ..< nm: f[i * nl + j] += c[i * nm + k] * d[k * nl + j]
  for i in 0 ..< ni:
    for j in 0 ..< nl:
      g[i * nl + j] = 0.0
      for k in 0 ..< nj: g[i * nl + j] += e[i * nj + k] * f[k * nl + j]
  var checksum = 0.0
  for i in 0 ..< ni:
    for j in 0 ..< nl: checksum += g[i * nl + j]
  checksum
