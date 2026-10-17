const MaxInputValues = 300
const MaxTrainingCount = 32
const MaxFeatureCount = 8

proc k_nn*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_nn".} =
  if input == nil or length < 3 or length > MaxInputValues.csize_t: return -1
  let trainingValue = input[0]
  let featureValue = input[1]
  let neighborValue = input[2]
  if trainingValue < 1 or trainingValue > MaxTrainingCount or
      featureValue < 1 or featureValue > MaxFeatureCount or
      neighborValue < 1 or neighborValue > trainingValue or neighborValue mod 2 == 0: return -1
  let trainingCount = int(trainingValue)
  let featureCount = int(featureValue)
  let neighborCount = int(neighborValue)
  let featureStart = 3
  let labelStart = featureStart + trainingCount * featureCount
  let queryStart = labelStart + trainingCount
  if length != csize_t(queryStart + featureCount): return -1
  for i in 0 ..< trainingCount * featureCount:
    let value = input[featureStart + i]
    if value < -32 or value > 32: return -1
  for row in 0 ..< trainingCount:
    if input[labelStart + row] != 0 and input[labelStart + row] != 1: return -1
  for feature in 0 ..< featureCount:
    let value = input[queryStart + feature]
    if value < -32 or value > 32: return -1

  var queryNorm = 0'i64
  for feature in 0 ..< featureCount:
    let query = input[queryStart + feature]
    queryNorm += query * query
  var distances: array[MaxTrainingCount, int64]
  var order: array[MaxTrainingCount, int]
  for row in 0 ..< trainingCount:
    var rowNorm = 0'i64
    var crossProduct = 0'i64
    for feature in 0 ..< featureCount:
      let coordinate = input[featureStart + row * featureCount + feature]
      let query = input[queryStart + feature]
      rowNorm += coordinate * coordinate
      crossProduct += coordinate * query
    distances[row] = queryNorm - 2 * crossProduct + rowNorm
    order[row] = row
  for row in 0 ..< trainingCount:
    for other in row + 1 ..< trainingCount:
      if distances[row] == distances[other]: return -1
  for position in 1 ..< trainingCount:
    let row = order[position]
    var cursor = position
    while cursor > 0 and distances[order[cursor - 1]] > distances[row]:
      order[cursor] = order[cursor - 1]
      dec cursor
    order[cursor] = row
  var zeroVotes = 0
  for position in 0 ..< neighborCount:
    if input[labelStart + order[position]] == 0: inc zeroVotes
  if zeroVotes > neighborCount div 2: 0 else: 1
