const MaxParseableInputLength = 45
const MaxSamples = 8
const MaxFeatures = 4
const MaxFeatureValues = MaxSamples * MaxFeatures

proc linear_regression_vectorized*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "linear_regression_vectorized".} =
  if input == nil or length < 4 or length > csize_t(MaxParseableInputLength): return -1
  let sampleValue = input[0]
  let featureValue = input[1]
  let iterationValue = input[2]
  if sampleValue != sampleValue or sampleValue < 2.0 or sampleValue > float64(MaxSamples) or
      featureValue != featureValue or featureValue < 2.0 or featureValue > float64(MaxFeatures) or
      iterationValue != iterationValue or iterationValue < 10.0 or iterationValue > 128.0: return -1
  let sampleCount = int(sampleValue)
  let featureCount = int(featureValue)
  let iterations = int(iterationValue)
  if float64(sampleCount) != sampleValue or float64(featureCount) != featureValue or
      float64(iterations) != iterationValue: return -1
  if length != csize_t(4 + sampleCount * featureCount + sampleCount): return -1

  let alpha = input[3]
  if alpha != alpha or alpha < 0.0001 or alpha > 0.01: return -1

  var features: array[MaxFeatureValues, float64]
  var labels: array[MaxSamples, float64]
  let featureValues = sampleCount * featureCount
  for index in 0 ..< featureValues:
    let value = input[4 + index]
    if value != value or value < -1.0 or value > 1.0: return -1
    features[index] = value
  for row in 0 ..< sampleCount:
    if features[row * featureCount] != 1.0: return -1
  for row in 0 ..< sampleCount:
    let value = input[4 + featureValues + row]
    if value != value or value < -1.0 or value > 1.0: return -1
    labels[row] = value
  if output == nil or outputCapacity < csize_t(featureCount): return -2

  var theta: array[MaxFeatures, float64]
  var errors: array[MaxSamples, float64]
  var gradients: array[MaxFeatures, float64]
  for iteration in 0 ..< iterations:
    for row in 0 ..< sampleCount:
      var prediction = 0.0
      for column in 0 ..< featureCount:
        prediction += features[row * featureCount + column] * theta[column]
      errors[row] = prediction - labels[row]
    for column in 0 ..< featureCount:
      var gradient = 0.0
      for row in 0 ..< sampleCount:
        gradient += features[row * featureCount + column] * errors[row]
      gradients[column] = gradient / float64(sampleCount)
    for column in 0 ..< featureCount:
      theta[column] -= alpha * gradients[column]
  for column in 0 ..< featureCount: output[column] = theta[column]
  int64(featureCount)
