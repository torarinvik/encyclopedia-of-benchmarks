import std/math

const MaxInputLength = 18

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum) or floor(value) != value: return false
  true

proc polynomial_regression*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "polynomial_regression".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, 3) or not exactInteger(input[1], 1, 5) or
      not exactInteger(input[2], 1, 4): return -1
  let degree = int(input[0])
  let trainingCount = int(input[1])
  let queryCount = int(input[2])
  let columns = degree + 1
  if trainingCount < columns or inputLength != csize_t(3 + 2 * trainingCount + queryCount): return -1

  var xTrain, yTrain: array[5, float64]
  var xQuery: array[4, float64]
  for i in 0 ..< trainingCount:
    let x = input[3 + i]
    let y = input[3 + trainingCount + i]
    if not exactInteger(x, -2, 2) or not exactInteger(y, -32, 32): return -1
    xTrain[i] = x
    yTrain[i] = y
  for i in 0 ..< queryCount:
    let x = input[3 + 2 * trainingCount + i]
    if not exactInteger(x, -2, 2): return -1
    xQuery[i] = x
  for i in 0 ..< trainingCount:
    for j in i + 1 ..< trainingCount:
      if xTrain[i] == xTrain[j]: return -1

  var design: array[5, array[4, float64]]
  for row in 0 ..< trainingCount:
    var power = 1.0
    for column in 0 ..< columns:
      design[row][column] = power
      power *= xTrain[row]
  var qMatrix: array[5, array[4, float64]]
  var rMatrix: array[4, array[4, float64]]
  for column in 0 ..< columns:
    var vector: array[5, float64]
    for row in 0 ..< trainingCount: vector[row] = design[row][column]
    for previous in 0 ..< column:
      var dot = 0.0
      for row in 0 ..< trainingCount: dot += qMatrix[row][previous] * design[row][column]
      rMatrix[previous][column] = dot
      for row in 0 ..< trainingCount: vector[row] -= dot * qMatrix[row][previous]
    var normSquared = 0.0
    for row in 0 ..< trainingCount: normSquared += vector[row] * vector[row]
    if classify(normSquared) in {fcNan, fcInf, fcNegInf} or normSquared <= 0.0: return -1
    let norm = sqrt(normSquared)
    if classify(norm) in {fcNan, fcInf, fcNegInf} or norm <= 0.0: return -1
    rMatrix[column][column] = norm
    for row in 0 ..< trainingCount: qMatrix[row][column] = vector[row] / norm

  var projected: array[4, float64]
  for column in 0 ..< columns:
    for row in 0 ..< trainingCount: projected[column] += qMatrix[row][column] * yTrain[row]
  var coefficients: array[4, float64]
  for reverse in 0 ..< columns:
    let column = columns - reverse - 1
    var value = projected[column]
    for next in column + 1 ..< columns: value -= rMatrix[column][next] * coefficients[next]
    let diagonal = rMatrix[column][column]
    if classify(diagonal) in {fcNan, fcInf, fcNegInf} or diagonal == 0.0: return -1
    coefficients[column] = value / diagonal
    if classify(coefficients[column]) in {fcNan, fcInf, fcNegInf}: return -1

  let outputLength = columns + queryCount
  var staged: array[8, float64]
  for column in 0 ..< columns: staged[column] = coefficients[column]
  for query in 0 ..< queryCount:
    var prediction = 0.0
    var power = 1.0
    for column in 0 ..< columns:
      prediction += power * coefficients[column]
      power *= xQuery[query]
    if classify(prediction) in {fcNan, fcInf, fcNegInf}: return -1
    staged[columns + query] = prediction
  if output == nil or capacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength: output[i] = staged[i]
  int64(outputLength)
