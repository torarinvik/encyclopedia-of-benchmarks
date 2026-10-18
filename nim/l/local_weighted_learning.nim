import std/math

const
  MaxN = 16
  MaxD = 4
  MaxParseableInputLength = 84
  PivotFloor = 3.814697265625e-6

proc finiteValue(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc exactInteger(value: float64, minimum, maximum: int64, result: var int): bool =
  if not finiteValue(value) or value < float64(minimum) or value > float64(maximum): return false
  if trunc(value) != value: return false
  result = int(value)
  true

proc gridValue(value, minimum, maximum: float64): bool =
  if not finiteValue(value) or value < minimum or value > maximum: return false
  let scaled = value * 16.0
  finiteValue(scaled) and trunc(scaled) == scaled

proc solvePartialPivot(matrixInput: array[MaxD, array[MaxD, float64]],
                       rhsInput: array[MaxD, float64], dimension: int,
                       solution: var array[MaxD, float64]): bool =
  var matrix = matrixInput
  var rhs = rhsInput
  var scale = 0.0
  for index in 0 ..< dimension:
    let diagonal = abs(matrix[index][index])
    if not finiteValue(diagonal): return false
    if diagonal > scale: scale = diagonal
  if scale == 0.0 or not finiteValue(scale): return false

  for pivotColumn in 0 ..< dimension:
    var pivotRow = pivotColumn
    var pivotMagnitude = abs(matrix[pivotRow][pivotColumn])
    for candidate in pivotColumn + 1 ..< dimension:
      let candidateMagnitude = abs(matrix[candidate][pivotColumn])
      if not finiteValue(candidateMagnitude): return false
      if candidateMagnitude > pivotMagnitude:
        pivotRow = candidate
        pivotMagnitude = candidateMagnitude
    if not finiteValue(pivotMagnitude) or pivotMagnitude <= PivotFloor * scale: return false

    if pivotRow != pivotColumn:
      for column in 0 ..< dimension:
        swap(matrix[pivotColumn][column], matrix[pivotRow][column])
      swap(rhs[pivotColumn], rhs[pivotRow])

    let pivot = matrix[pivotColumn][pivotColumn]
    for row in pivotColumn + 1 ..< dimension:
      let factor = matrix[row][pivotColumn] / pivot
      if not finiteValue(factor): return false
      matrix[row][pivotColumn] = 0.0
      for column in pivotColumn + 1 ..< dimension:
        let product = factor * matrix[pivotColumn][column]
        matrix[row][column] = matrix[row][column] - product
        if not finiteValue(matrix[row][column]): return false
      let product = factor * rhs[pivotColumn]
      rhs[row] = rhs[row] - product
      if not finiteValue(rhs[row]): return false

  for reverseIndex in countdown(dimension - 1, 0):
    var residual = rhs[reverseIndex]
    for column in reverseIndex + 1 ..< dimension:
      let product = matrix[reverseIndex][column] * solution[column]
      residual = residual - product
    let diagonal = matrix[reverseIndex][reverseIndex]
    if not finiteValue(residual) or diagonal == 0.0 or not finiteValue(diagonal): return false
    solution[reverseIndex] = residual / diagonal
    if not finiteValue(solution[reverseIndex]): return false
  true

proc local_weighted_learning*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "local_weighted_learning".} =
  if input == nil or inputLength < 3 or inputLength > csize_t(MaxParseableInputLength): return -1
  var n = 0
  var d = 0
  if not exactInteger(input[0], 2, int64(MaxN), n) or not exactInteger(input[1], 1, int64(MaxD), d): return -1
  if d > n: return -1
  let tau = input[2]
  if not gridValue(tau, 2.0, 8.0): return -1
  let expectedLength = 3 + n * d + n
  if int(inputLength) != expectedLength: return -1

  var xTrain: array[MaxN, array[MaxD, float64]]
  var yTrain: array[MaxN, float64]
  var cursor = 3
  for row in 0 ..< n:
    for feature in 0 ..< d:
      let value = input[cursor]
      inc cursor
      if not gridValue(value, -4.0, 4.0): return -1
      xTrain[row][feature] = value
  for row in 0 ..< n:
    let value = input[cursor]
    inc cursor
    if not gridValue(value, -8.0, 8.0): return -1
    yTrain[row] = value

  var staged: array[MaxN, float64]
  for query in 0 ..< n:
    var weights: array[MaxN, float64]
    for row in 0 ..< n:
      var distanceSquared = 0.0
      for feature in 0 ..< d:
        let delta = xTrain[query][feature] - xTrain[row][feature]
        let squaredDelta = delta * delta
        distanceSquared = distanceSquared + squaredDelta
      let tauSquared = tau * tau
      let denominator = (-2.0) * tauSquared
      let exponent = distanceSquared / denominator
      weights[row] = exp(exponent)
      if not finiteValue(weights[row]) or weights[row] <= 0.0: return -1

    var normal: array[MaxD, array[MaxD, float64]]
    var rhs: array[MaxD, float64]
    for row in 0 ..< n:
      var weightedX: array[MaxD, float64]
      for feature in 0 ..< d: weightedX[feature] = weights[row] * xTrain[row][feature]
      let weightedY = weights[row] * yTrain[row]
      for p in 0 ..< d:
        let rhsProduct = xTrain[row][p] * weightedY
        rhs[p] = rhs[p] + rhsProduct
        for q in 0 ..< d:
          let product = xTrain[row][p] * weightedX[q]
          normal[p][q] = normal[p][q] + product

    var coefficients: array[MaxD, float64]
    if not solvePartialPivot(normal, rhs, d, coefficients): return -1
    var prediction = 0.0
    for feature in 0 ..< d:
      let product = xTrain[query][feature] * coefficients[feature]
      prediction = prediction + product
    if not finiteValue(prediction): return -1
    staged[query] = prediction

  if output == nil or outputCapacity < csize_t(n): return -2
  for index in 0 ..< n: output[index] = staged[index]
  int64(n)
