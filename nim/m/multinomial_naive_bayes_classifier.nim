## Fit and batch-predict with a bounded multinomial Naive Bayes model.
import math

proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc multinomial_naive_bayes_classifier*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                                         output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                                         {.cdecl, exportc: "multinomial_naive_bayes_classifier".} =
  if input.isNil or inputLength < 1 or inputLength > 360: return -1
  let fitCountValue = input[0]
  if fitCountValue < 1 or fitCountValue > 2: return -1
  let fitCount = int(fitCountValue)
  var position = 1
  var featureWidth = 0
  var trainingRows: int64 = 0
  var classCounts: array[8, int64]
  var featureSums: array[64, float64]
  var classTotals: array[8, float64]
  var labels: array[16, int64]
  var trainingFeatures: array[128, int64]

  for fit in 0..<fitCount:
    if position + 2 > int(inputLength): return -1
    let rowsValue = input[position]
    inc position
    let widthValue = input[position]
    inc position
    if rowsValue < 1 or rowsValue > 16 or widthValue < 1 or widthValue > 8: return -1
    let rows = int(rowsValue)
    let width = int(widthValue)
    if position + rows + rows * width > int(inputLength): return -1
    for row in 0..<rows:
      let label = input[position]
      inc position
      if label < 0 or label > 7: return -1
      labels[row] = label
    for index in 0..<rows * width:
      let count = input[position]
      inc position
      if count < 0 or count > 100: return -1
      trainingFeatures[index div width * 8 + index mod width] = count

    for label in 0..<8:
      classCounts[label] = 0
      classTotals[label] = 0.0
    for index in 0..<64: featureSums[index] = 0.0
    trainingRows = rowsValue
    featureWidth = width
    for row in 0..<rows:
      let label = int(labels[row])
      inc classCounts[label]
      for column in 0..<width:
        let count = float64(trainingFeatures[row * 8 + column])
        featureSums[label * 8 + column] += count
        classTotals[label] += count

  if position + 2 > int(inputLength): return -1
  let predictionCountValue = input[position]
  inc position
  let predictionWidthValue = input[position]
  inc position
  if predictionCountValue < 1 or predictionCountValue > 8 or predictionWidthValue < 1 or predictionWidthValue > 8 or int(predictionWidthValue) != featureWidth: return -1
  let predictionCount = int(predictionCountValue)
  let predictionWidth = int(predictionWidthValue)
  if position + predictionCount * predictionWidth != int(inputLength): return -1
  var predictionFeatures: array[64, int64]
  for index in 0..<predictionCount * predictionWidth:
    let count = input[position]
    inc position
    if count < 0 or count > 100: return -1
    predictionFeatures[index div predictionWidth * 8 + index mod predictionWidth] = count

  var predictions: array[8, int64]
  for row in 0..<predictionCount:
    var bestScore = NegInf
    var secondScore = NegInf
    var bestLabel: int64 = -1
    for label in 0..<8:
      if classCounts[label] == 0: continue
      var score = ln(float64(classCounts[label]) / float64(trainingRows))
      let denominator = classTotals[label] + float64(featureWidth)
      for column in 0..<featureWidth:
        let likelihood = (featureSums[label * 8 + column] + 1.0) / denominator
        score += float64(predictionFeatures[row * 8 + column]) * ln(likelihood)
      if score > bestScore:
        secondScore = bestScore
        bestScore = score
        bestLabel = int64(label)
      elif score > secondScore:
        secondScore = score
    if bestLabel < 0 or (secondScore != NegInf and bestScore - secondScore < 1e-8): return -1
    predictions[row] = bestLabel

  let outputWords = predictionCount + 1
  let outputBytes = outputWords * 8
  if output.isNil or outputCapacity < csize_t(outputBytes) or outputBytes > 72: return -2
  putI64Le(output, 0, predictionCountValue)
  for index in 0..<predictionCount:
    putI64Le(output, index + 1, predictions[index])
  int64(outputBytes)
