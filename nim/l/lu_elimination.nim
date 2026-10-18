import std/math

const MaxInputLength = 22
const MaxDimension = 4

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc lu_elimination*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "lu_elimination".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, MaxDimension): return -1
  let dimension = int(input[0])
  let matrixElements = dimension * dimension
  if inputLength != csize_t(1 + matrixElements + dimension): return -1

  var matrix: array[16, float64]
  var rhs: array[4, float64]
  for index in 0 ..< matrixElements:
    let value = input[csize_t(1 + index)]
    if not exactInteger(value, -1, 1): return -1
    matrix[index] = value
  for index in 0 ..< dimension:
    let value = input[csize_t(1 + matrixElements + index)]
    if not exactInteger(value, -8, 8): return -1
    rhs[index] = value

  var lower: array[16, float64]
  var upper: array[16, float64]
  for row in 0 ..< dimension:
    for column in row ..< dimension:
      var sum = 0.0
      for index in 0 ..< row: sum += lower[row * dimension + index] * upper[index * dimension + column]
      upper[row * dimension + column] = matrix[row * dimension + column] - sum
    let pivot = upper[row * dimension + row]
    if pivot == 0.0 or classify(pivot) in {fcNan, fcInf, fcNegInf}: return -1
    for column in row ..< dimension:
      if row == column:
        lower[row * dimension + row] = 1.0
      else:
        var sum = 0.0
        for index in 0 ..< row: sum += lower[column * dimension + index] * upper[index * dimension + row]
        lower[column * dimension + row] = (matrix[column * dimension + row] - sum) / pivot
        if classify(lower[column * dimension + row]) in {fcNan, fcInf, fcNegInf}: return -1

  var transformed: array[4, float64]
  for row in 0 ..< dimension:
    var sum = 0.0
    for column in 0 ..< row: sum += transformed[column] * lower[row * dimension + column]
    transformed[row] = (rhs[row] - sum) / lower[row * dimension + row]
    if classify(transformed[row]) in {fcNan, fcInf, fcNegInf}: return -1

  var solution: array[4, float64]
  if dimension > 0:
    for row in countdown(dimension - 1, 0):
      var sum = 0.0
      for column in row ..< dimension: sum += solution[column] * upper[row * dimension + column]
      let pivot = upper[row * dimension + row]
      if pivot == 0.0 or classify(pivot) in {fcNan, fcInf, fcNegInf}: return -1
      solution[row] = (transformed[row] - sum) / pivot
      if classify(solution[row]) in {fcNan, fcInf, fcNegInf}: return -1

  if output == nil or capacity < csize_t(dimension): return -2
  for index in 0 ..< dimension: output[index] = solution[index]
  int64(dimension)
