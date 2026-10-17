import std/math

const MaxDimension = 4
const MaxInputLength = 26
const MaxOutputElements = 16

proc sherman_morrison*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sherman_morrison".} =
  if input.isNil or inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
  let dimensionValue = input[0]
  if classify(dimensionValue) in {fcNan, fcInf, fcNegInf} or
      floor(dimensionValue) != dimensionValue or dimensionValue < 1.0 or dimensionValue > float64(MaxDimension): return -1
  let dimension = int(dimensionValue)
  let expectedLength = 1 + dimension * dimension + 2 * dimension
  if inputLength != csize_t(expectedLength): return -1

  var coefficients: array[MaxOutputElements + 2 * MaxDimension, float64]
  for index in 0 ..< expectedLength - 1:
    let value = input[1 + index]
    if classify(value) in {fcNan, fcInf, fcNegInf} or floor(value) != value or value < -2.0 or value > 2.0: return -1
    coefficients[index] = value

  let matrixElements = dimension * dimension
  var matrix: array[MaxDimension, array[MaxDimension, float64]]
  var u, v: array[MaxDimension, float64]
  for row in 0 ..< dimension:
    for column in 0 ..< dimension:
      matrix[row][column] = coefficients[row * dimension + column]
  for index in 0 ..< dimension:
    u[index] = coefficients[matrixElements + index]
    v[index] = coefficients[matrixElements + dimension + index]

  var right: array[MaxDimension, float64]
  for column in 0 ..< dimension:
    for inner in 0 ..< dimension:
      right[column] += v[inner] * matrix[inner][column]
  var denominator = 0.0
  for inner in 0 ..< dimension:
    denominator += right[inner] * u[inner]
  denominator += 1.0

  var updated: array[MaxOutputElements, float64]
  if denominator != 0.0:
    var left: array[MaxDimension, float64]
    for row in 0 ..< dimension:
      for inner in 0 ..< dimension:
        left[row] += matrix[row][inner] * u[inner]
    let reciprocal = 1.0 / denominator
    for row in 0 ..< dimension:
      for column in 0 ..< dimension:
        let outerProduct = left[row] * right[column]
        let scaledProduct = outerProduct * reciprocal
        updated[row * dimension + column] = matrix[row][column] - scaledProduct

  if output.isNil: return -2
  if denominator == 0.0: return 0
  if outputCapacity < csize_t(dimension * dimension): return -2
  for index in 0 ..< dimension * dimension:
    output[index] = updated[index]
  int64(dimension * dimension)
