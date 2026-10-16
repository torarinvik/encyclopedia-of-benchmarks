const Modulus = 1_000_000_007'i64
const MaxInputLength = 24

type Matrix4 = array[16, int64]

proc multiplyMatrix(left, right: Matrix4, dimension: int): Matrix4 =
  var output: Matrix4
  for row in 0 ..< dimension:
    for column in 0 ..< dimension:
      var value = 0'i64
      for inner in 0 ..< dimension:
        value = (value + (left[row * dimension + inner] mod Modulus) *
                         (right[inner * dimension + column] mod Modulus) mod Modulus) mod Modulus
      output[row * dimension + column] = value
  output

proc matrixPower(matrix: Matrix4, dimension: int, initialPower: int64): Matrix4 =
  var zero = true
  for index in 0 ..< dimension * dimension:
    if matrix[index] != 0: zero = false
  if zero: return default(Matrix4)
  var result: Matrix4
  var base = matrix
  for index in 0 ..< dimension: result[index * dimension + index] = 1
  var power = initialPower
  while power > 0:
    if (power and 1) != 0: result = multiplyMatrix(result, base, dimension)
    power = power div 2
    base = multiplyMatrix(base, base, dimension)
  result

proc linear_recurrence_matrix*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "linear_recurrence_matrix".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let dimensionValue = input[0]
  let nthTerm = input[1]
  let constantOrSumIncluded = input[2]
  if dimensionValue < 1 or dimensionValue > 4 or nthTerm < 0 or nthTerm > 1_000_000 or
      (constantOrSumIncluded != 0 and constantOrSumIncluded != 1): return -1
  let dimension = int(dimensionValue)
  let matrixCount = dimension * dimension
  if length != csize_t(3 + matrixCount + dimension): return -1
  if constantOrSumIncluded == 1 and nthTerm < dimensionValue - 1: return -1
  var matrix: Matrix4
  var baseRow: array[4, int64]
  for index in 0 ..< matrixCount + dimension:
    let value = input[3 + index]
    if value < 0 or value >= Modulus: return -1
    if index < matrixCount: matrix[index] = value
    else: baseRow[index - matrixCount] = value
  if nthTerm < dimensionValue - constantOrSumIncluded:
    return baseRow[int(nthTerm - constantOrSumIncluded)]
  let power = nthTerm - int64(dimension) + 1 + constantOrSumIncluded
  let result = matrixPower(matrix, dimension, power)
  var value = 0'i64
  for index in 0 ..< dimension:
    value = (value + (baseRow[index] mod Modulus) *
             (result[index * dimension + dimension - 1] mod Modulus) mod Modulus) mod Modulus
  value
