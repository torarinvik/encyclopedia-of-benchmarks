const MaxObservations = 64
const MaxFeatures = 16
const MaxInputLength = 2 + MaxObservations * MaxFeatures + MaxFeatures + MaxObservations
const InvalidResult = -1.0e300

proc linear_regression_cost*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "linear_regression_cost".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return InvalidResult
  let observationValue = values[0]
  let featureValue = values[1]
  if observationValue < 1 or observationValue > MaxObservations or
      featureValue < 1 or featureValue > MaxFeatures: return InvalidResult
  let observations = int(observationValue)
  let features = int(featureValue)
  let matrixLength = observations * features
  if int(length) != 2 + matrixLength + features + observations: return InvalidResult
  for index in 2 ..< int(length):
    if values[index] < -1000 or values[index] > 1000: return InvalidResult

  let weightsStart = 2 + matrixLength
  let targetsStart = weightsStart + features
  var squaredErrorSum = 0.0
  for row in 0 ..< observations:
    var prediction = 0.0
    let rowStart = 2 + row * features
    for column in 0 ..< features:
      prediction += float64(values[rowStart + column]) * float64(values[weightsStart + column])
    let error = prediction - float64(values[targetsStart + row])
    squaredErrorSum += error * error
  squaredErrorSum / (2.0 * float64(observations))
