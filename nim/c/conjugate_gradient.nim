import std/math

const MaxDimension = 8
const MaxEntryMicro = 1_000_000_000'i64
const Scale = 1_000_000.0
const Tolerance = 1.0e-10
const MaxIterations = 1000

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc conjugate_gradient*(values: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "conjugate_gradient".} =
  if values.isNil or length < 1 or values[0] < 1 or values[0] > MaxDimension: return -1
  let n = int(values[0])
  if length != csize_t(1 + n * n + n): return -1
  let vectorOffset = 1 + n * n
  var matrix: array[MaxDimension * MaxDimension, float64]
  var rhs, solution, residual, direction, product: array[MaxDimension, float64]
  for index in 0 ..< n * n + n:
    if values[index + 1] < -MaxEntryMicro or values[index + 1] > MaxEntryMicro: return -1
  for row in 0 ..< n:
    let diagonal = values[1 + row * n + row]
    if diagonal <= 0: return -1
    var offDiagonalSum = 0'i64
    for column in 0 ..< n:
      let entry = values[1 + row * n + column]
      if entry != values[1 + column * n + row]: return -1
      if column != row: offDiagonalSum += abs(entry)
      matrix[row * n + column] = float64(entry) / Scale
    if diagonal <= offDiagonalSum: return -1
    rhs[row] = float64(values[vectorOffset + row]) / Scale
    residual[row] = rhs[row]
    direction[row] = rhs[row]
  let outputBytes = n * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2

  var residualSquared = 0.0
  for index in 0 ..< n: residualSquared += residual[index] * residual[index]
  for iteration in 0 ..< MaxIterations:
    if residualSquared <= Tolerance * Tolerance: break
    for row in 0 ..< n:
      product[row] = 0.0
      for column in 0 ..< n: product[row] += matrix[row * n + column] * direction[column]
    var denominator = 0.0
    for index in 0 ..< n: denominator += direction[index] * product[index]
    if denominator <= 0.0: return -1
    let alpha = residualSquared / denominator
    for index in 0 ..< n:
      solution[index] += alpha * direction[index]
      residual[index] -= alpha * product[index]
    var nextResidualSquared = 0.0
    for index in 0 ..< n: nextResidualSquared += residual[index] * residual[index]
    if nextResidualSquared <= Tolerance * Tolerance:
      residualSquared = nextResidualSquared
      break
    let beta = nextResidualSquared / residualSquared
    for index in 0 ..< n: direction[index] = residual[index] + beta * direction[index]
    residualSquared = nextResidualSquared
  for index in 0 ..< n: writeF64Le(output, index * 8, solution[index])
  int64(outputBytes)
