import std/math

const
  MaxGroupCount = 4
  MaxRows = 4
  MaxColumns = 4
  MaxMatrixElements = 16
  MaxGroupMatrixElements = 32
  MaxCallCount = 8
  MaxValidInputLength = 271
  MaxParseableInputLength = 272

proc finiteValue(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc orthogonalize(gradient: ptr UncheckedArray[float64], rows, columns, nsSteps: int,
    result: var array[MaxMatrixElements, float64]) =
  let transposed = rows < columns
  let workingRows = if transposed: columns else: rows
  let workingColumns = if transposed: rows else: columns
  var matrix: array[MaxMatrixElements, float64]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      if transposed:
        matrix[column * workingColumns + row] = gradient[row * columns + column]
      else:
        matrix[row * workingColumns + column] = gradient[row * columns + column]
  for _ in 0 ..< nsSteps:
    var gram: array[MaxMatrixElements, float64]
    var product: array[MaxMatrixElements, float64]
    for left in 0 ..< workingColumns:
      for right in 0 ..< workingColumns:
        var sum = 0.0
        for row in 0 ..< workingRows:
          sum += matrix[row * workingColumns + left] * matrix[row * workingColumns + right]
        gram[left * workingColumns + right] = sum
    for row in 0 ..< workingRows:
      for column in 0 ..< workingColumns:
        var sum = 0.0
        for inner in 0 ..< workingColumns:
          sum += matrix[row * workingColumns + inner] * gram[inner * workingColumns + column]
        product[row * workingColumns + column] = sum
    for row in 0 ..< workingRows:
      for column in 0 ..< workingColumns:
        let index = row * workingColumns + column
        matrix[index] = 1.5 * matrix[index] - 0.5 * product[index]
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      result[row * columns + column] =
        if transposed: matrix[column * workingColumns + row]
        else: matrix[row * workingColumns + column]

proc muon_optimizer*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "muon_optimizer".} =
  if input == nil or inputLength < 10 or inputLength > MaxParseableInputLength.csize_t:
    return -1
  for index in 0 ..< int(inputLength):
    if not finiteValue(input[index]): return -1
  let groupValue = input[0]
  let rowsValue = input[1]
  let columnsValue = input[2]
  let callsValue = input[3]
  let stepsValue = input[4]
  if groupValue < 1.0 or groupValue > float64(MaxGroupCount) or
      rowsValue < 1.0 or rowsValue > float64(MaxRows) or
      columnsValue < 1.0 or columnsValue > float64(MaxColumns) or
      callsValue < 1.0 or callsValue > float64(MaxCallCount) or
      stepsValue < 0.0 or stepsValue > 5.0:
    return -1
  let groupCount = int(groupValue)
  let rows = int(rowsValue)
  let columns = int(columnsValue)
  let callCount = int(callsValue)
  let nsSteps = int(stepsValue)
  if float64(groupCount) != groupValue or float64(rows) != rowsValue or
      float64(columns) != columnsValue or float64(callCount) != callsValue or
      float64(nsSteps) != stepsValue:
    return -1
  let matrixElements = rows * columns
  if matrixElements > MaxMatrixElements or groupCount * matrixElements > MaxGroupMatrixElements or
      callCount < groupCount:
    return -1
  if int(inputLength) != 7 + callCount * (1 + 2 * matrixElements) or
      int(inputLength) > MaxValidInputLength:
    return -1
  let learningRate = input[5]
  let momentum = input[6]
  if learningRate < 0.0 or learningRate > 0.25 or momentum < 0.0 or momentum > 0.99:
    return -1

  var ids: array[MaxCallCount, int]
  var eventParams: array[MaxCallCount * MaxMatrixElements, float64]
  var eventGradients: array[MaxCallCount * MaxMatrixElements, float64]
  var seen: array[MaxGroupCount, bool]
  var cursor = 7
  for event in 0 ..< callCount:
    let idValue = input[cursor]
    if idValue < 0.0 or idValue >= float64(groupCount): return -1
    let id = int(idValue)
    if float64(id) != idValue: return -1
    ids[event] = id
    seen[id] = true
    inc cursor
    for element in 0 ..< matrixElements:
      let value = input[cursor + element]
      if value < -10.0 or value > 10.0: return -1
      eventParams[event * matrixElements + element] = value
    cursor += matrixElements
    for element in 0 ..< matrixElements:
      let value = input[cursor + element]
      if value < -0.01 or value > 0.01: return -1
      eventGradients[event * matrixElements + element] = value
    cursor += matrixElements
  for id in 0 ..< groupCount:
    if not seen[id]: return -1

  let groupElements = groupCount * matrixElements
  let outputElements = 2 * groupElements
  if output == nil or outputCapacity < outputElements.csize_t: return -2
  var velocities: array[MaxGroupMatrixElements, float64]
  var lastParams: array[MaxGroupMatrixElements, float64]
  for event in 0 ..< callCount:
    let id = ids[event]
    let stateOffset = id * matrixElements
    var orthogonalized: array[MaxMatrixElements, float64]
    orthogonalize(addr eventGradients[event * matrixElements], rows, columns, nsSteps, orthogonalized)
    for element in 0 ..< matrixElements:
      let stateIndex = stateOffset + element
      let eventIndex = event * matrixElements + element
      velocities[stateIndex] = momentum * velocities[stateIndex] + orthogonalized[element]
      lastParams[stateIndex] = eventParams[eventIndex] - learningRate * velocities[stateIndex]
  for index in 0 ..< groupElements:
    output[index] = lastParams[index]
    output[groupElements + index] = velocities[index]
  int64(outputElements)
