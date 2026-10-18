import std/math

const MaxInputLength = 18
const MaxDimension = 4

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc qr_decomposition*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "qr_decomposition".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, MaxDimension): return -1
  let dimension = int(input[0])
  let matrixElements = dimension * dimension
  if inputLength != csize_t(1 + matrixElements): return -1

  var matrix: array[16, float64]
  var exact: array[16, int64]
  for index in 0 ..< matrixElements:
    let value = input[csize_t(index + 1)]
    if not exactInteger(value, -1, 1): return -1
    matrix[index] = value
    exact[index] = int64(value)

  var previousPivot = 1'i64
  for pivotColumn in 0 ..< dimension:
    let pivot = exact[pivotColumn * dimension + pivotColumn]
    if pivot == 0: return -1
    for row in pivotColumn + 1 ..< dimension:
      for column in pivotColumn + 1 ..< dimension:
        let numerator = exact[row * dimension + column] * pivot -
          exact[row * dimension + pivotColumn] * exact[pivotColumn * dimension + column]
        exact[row * dimension + column] = numerator div previousPivot
      exact[row * dimension + pivotColumn] = 0
    previousPivot = pivot

  var q: array[16, float64]
  var r: array[16, float64]
  for column in 0 ..< dimension:
    var residual: array[4, float64]
    for row in 0 ..< dimension: residual[row] = matrix[row * dimension + column]
    for previous in 0 ..< column:
      var projection = 0.0
      for row in 0 ..< dimension: projection += q[row * dimension + previous] * residual[row]
      r[previous * dimension + column] = projection
      for row in 0 ..< dimension: residual[row] -= projection * q[row * dimension + previous]
    var squared = 0.0
    for row in 0 ..< dimension: squared += residual[row] * residual[row]
    let magnitude = sqrt(squared)
    if magnitude == 0.0 or classify(magnitude) in {fcNan, fcInf, fcNegInf}: return -1
    r[column * dimension + column] = magnitude
    for row in 0 ..< dimension: q[row * dimension + column] = residual[row] / magnitude

  var reconstructionSquared = 0.0
  var orthogonalitySquared = 0.0
  var lowerSquared = 0.0
  for row in 0 ..< dimension:
    for column in 0 ..< dimension:
      var reconstructed = 0.0
      var orthogonality = 0.0
      for inner in 0 ..< dimension:
        reconstructed += q[row * dimension + inner] * r[inner * dimension + column]
        orthogonality += q[inner * dimension + row] * q[inner * dimension + column]
      let reconstructionError = matrix[row * dimension + column] - reconstructed
      reconstructionSquared += reconstructionError * reconstructionError
      if row == column: orthogonality -= 1.0
      orthogonalitySquared += orthogonality * orthogonality
      if row > column: lowerSquared += r[row * dimension + column] * r[row * dimension + column]
  let result = [sqrt(reconstructionSquared), sqrt(orthogonalitySquared), sqrt(lowerSquared)]
  for value in result:
    if classify(value) in {fcNan, fcInf, fcNegInf}: return -1
  if output == nil or capacity < 3: return -2
  for index in 0 ..< 3: output[index] = result[index]
  3
