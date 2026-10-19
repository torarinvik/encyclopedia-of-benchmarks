const MaxDimension = 16
const MaxACells = MaxDimension * MaxDimension * MaxDimension
const MaxC4Cells = MaxDimension * MaxDimension
const InvalidResult = -1e300

type Tensor = array[MaxACells, float64]
type Matrix = array[MaxC4Cells, float64]
type Vector = array[MaxDimension, float64]

proc doitgen*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "doitgen".} =
  if values == nil or length != 3: return InvalidResult
  if values[0] < 1 or values[0] > MaxDimension or values[1] < 1 or values[1] > MaxDimension or
     values[2] < 1 or values[2] > MaxDimension: return InvalidResult
  let nr = int(values[0])
  let nq = int(values[1])
  let np = int(values[2])
  var a: Tensor
  var c4: Matrix
  var sums: Vector
  for r in 0 ..< nr:
    for q in 0 ..< nq:
      for p in 0 ..< np: a[(r * nq + q) * np + p] = float64((r * q + p) mod np) / float64(np)
  for i in 0 ..< np:
    for j in 0 ..< np: c4[i * np + j] = float64((i * j) mod np) / float64(np)
  for r in 0 ..< nr:
    for q in 0 ..< nq:
      for p in 0 ..< np:
        sums[p] = 0.0
        for s in 0 ..< np: sums[p] += a[(r * nq + q) * np + s] * c4[s * np + p]
      for p in 0 ..< np: a[(r * nq + q) * np + p] = sums[p]
  var checksum = 0.0
  for r in 0 ..< nr:
    for q in 0 ..< nq:
      for p in 0 ..< np: checksum += a[(r * nq + q) * np + p]
  checksum
