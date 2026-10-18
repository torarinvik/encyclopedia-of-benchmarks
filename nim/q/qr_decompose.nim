import std/math

const MaxInputLength = 18
const MaxDimension = 4

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc qr_decompose*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "qr_decompose".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, MaxDimension): return -1
  let dimension = int(input[0])
  let matrixElements = dimension * dimension
  if inputLength != csize_t(1 + matrixElements): return -1

  var matrix: array[16, float64]
  var bareiss: array[16, int64]
  for index in 0 ..< matrixElements:
    let value = input[csize_t(index + 1)]
    if not exactInteger(value, -4, 4): return -1
    matrix[index] = value
    bareiss[index] = int64(value)

  var sign = 1'i64
  var previousPivot = 1'i64
  for pivotColumn in 0 ..< dimension - 1:
    var pivotRow = pivotColumn
    while pivotRow < dimension and bareiss[pivotRow * dimension + pivotColumn] == 0: inc pivotRow
    if pivotRow == dimension: return -1
    if pivotRow != pivotColumn:
      for swapColumn in 0 ..< dimension:
        swap(bareiss[pivotColumn * dimension + swapColumn], bareiss[pivotRow * dimension + swapColumn])
      sign = -sign
    let pivotValue = bareiss[pivotColumn * dimension + pivotColumn]
    for row in pivotColumn + 1 ..< dimension:
      for column in pivotColumn + 1 ..< dimension:
        let numerator = bareiss[row * dimension + column] * pivotValue -
          bareiss[row * dimension + pivotColumn] * bareiss[pivotColumn * dimension + column]
        bareiss[row * dimension + column] = numerator div previousPivot
      bareiss[row * dimension + pivotColumn] = 0
    previousPivot = pivotValue
  if sign * bareiss[(dimension - 1) * dimension + dimension - 1] == 0: return -1

  var q: array[16, float64]
  var r: array[16, float64]
  for column in 0 ..< dimension:
    var source: array[4, float64]
    var residual: array[4, float64]
    for row in 0 ..< dimension:
      source[row] = matrix[row * dimension + column]
      residual[row] = source[row]
    for previous in 0 ..< column:
      var numerator = 0.0
      var denominator = 0.0
      for row in 0 ..< dimension:
        numerator += source[row] * q[row * dimension + previous]
        denominator += q[row * dimension + previous] * q[row * dimension + previous]
      if denominator == 0.0 or classify(denominator) in {fcNan, fcInf, fcNegInf}: return -1
      let scalar = numerator / denominator
      for row in 0 ..< dimension:
        residual[row] -= scalar * q[row * dimension + previous]

    var residualSquared = 0.0
    for row in 0 ..< dimension: residualSquared += residual[row] * residual[row]
    let magnitude = sqrt(residualSquared)
    if magnitude == 0.0 or classify(magnitude) in {fcNan, fcInf, fcNegInf}: return -1
    for row in 0 ..< dimension: q[row * dimension + column] = residual[row] / magnitude
    for targetColumn in column ..< dimension:
      var dot = 0.0
      for row in 0 ..< dimension: dot += q[row * dimension + column] * matrix[row * dimension + targetColumn]
      r[column * dimension + targetColumn] = dot

  for index in 0 ..< matrixElements:
    if classify(q[index]) in {fcNan, fcInf, fcNegInf} or classify(r[index]) in {fcNan, fcInf, fcNegInf}: return -1
  let outputLength = 2 * matrixElements
  if output == nil or capacity < csize_t(outputLength): return -2
  for index in 0 ..< matrixElements:
    output[index] = q[index]
    output[matrixElements + index] = r[index]
  int64(outputLength)
