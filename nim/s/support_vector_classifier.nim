import math

const MaxN = 8
const MaxD = 4
const MaxQ = 16
const MaxInputValues = 108

type
  FeatureRow = array[MaxD, float64]
  TrainingSet = array[MaxN, FeatureRow]
  TestingSet = array[MaxQ, FeatureRow]

proc kernelValue(left, right: FeatureRow, dimension, kind: int): float64 =
  if kind == 0:
    var total = 0.0
    for i in 0 ..< dimension: total += left[i] * right[i]
    return total
  var normSquared = 0.0
  for i in 0 ..< dimension:
    let difference = left[i] - right[i]
    normSquared += difference * difference
  exp(-normSquared)

proc fitPredict(labels: array[MaxN, float64], training: TrainingSet, testing: TestingSet,
    n, dimension, queryCount, kind: int): int64 =
  var kernelMatrix: array[MaxN, array[MaxN, float64]]
  for i in 0 ..< n:
    for j in 0 ..< n:
      kernelMatrix[i][j] = kernelValue(training[i], training[j], dimension, kind)

  var optimum: array[MaxN, float64]
  for i in 0 ..< n: optimum[i] = 0.5
  for iteration in 0 ..< 5000:
    var gradient: array[MaxN, float64]
    for i in 0 ..< n:
      var total = 0.0
      for j in 0 ..< n: total += optimum[j] * labels[j] * kernelMatrix[i][j]
      gradient[i] = labels[i] * total - 1.0
    let oldOptimum = optimum
    let learningRate = 0.1 / (1.0 + float64(iteration) / 1000.0)
    for i in 0 ..< n: optimum[i] = max(0.0, min(1.0, optimum[i] - learningRate * gradient[i]))

    var sumLabelLambda = 0.0
    for i in 0 ..< n: sumLabelLambda += optimum[i] * labels[i]
    var correction = sumLabelLambda / float64(n)
    for _ in 0 ..< 10:
      for i in 0 ..< n:
        optimum[i] = max(0.0, min(1.0, optimum[i] - correction * labels[i]))
      sumLabelLambda = 0.0
      for i in 0 ..< n: sumLabelLambda += optimum[i] * labels[i]
      correction = sumLabelLambda / float64(n)
      if abs(sumLabelLambda) < 1e-10: break
    var differenceSquared = 0.0
    for i in 0 ..< n:
      let difference = optimum[i] - oldOptimum[i]
      differenceSquared += difference * difference
    if sqrt(differenceSquared) < 1e-8: break

  var offsetTotal = 0.0
  var offsetCount = 0
  for i in 0 ..< n:
    if optimum[i] > 1e-5 and optimum[i] < 1.0 - 1e-5:
      var kernelSum = 0.0
      for j in 0 ..< n:
        kernelSum += optimum[j] * labels[j] * kernelValue(training[j], training[i], dimension, kind)
      offsetTotal += labels[i] - kernelSum
      inc offsetCount
  if offsetCount == 0:
    for i in 0 ..< n:
      var kernelSum = 0.0
      for j in 0 ..< n:
        kernelSum += optimum[j] * labels[j] * kernelValue(training[j], training[i], dimension, kind)
      offsetTotal += labels[i] - kernelSum
    offsetTotal /= float64(n)
  else:
    offsetTotal /= float64(offsetCount)

  var mask = 0'i64
  for i in 0 ..< queryCount:
    var total = 0.0
    for j in 0 ..< n:
      total += optimum[j] * labels[j] * kernelValue(training[j], testing[i], dimension, kind)
    if total + offsetTotal >= 0.0: mask = mask or (1'i64 shl i)
  mask

proc support_vector_classifier*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "support_vector_classifier".} =
  if input == nil or length < 4 or length > csize_t(MaxInputValues + 1): return -1
  if input[0] < 2 or input[0] > MaxN or input[1] < 1 or input[1] > MaxD or
      input[2] < 0 or input[2] > 1 or input[3] < 1 or input[3] > MaxQ: return -1
  let n = int(input[0])
  let dimension = int(input[1])
  let kind = int(input[2])
  let queryCount = int(input[3])
  if int(length) != 4 + n + n * dimension + queryCount * dimension: return -1

  var labels: array[MaxN, float64]
  var sawNegative = false
  var sawPositive = false
  for i in 0 ..< n:
    let label = input[4 + i]
    if label != -1 and label != 1: return -1
    labels[i] = float64(label)
    if label < 0: sawNegative = true
    else: sawPositive = true
  if not sawNegative or not sawPositive: return -1

  var training: TrainingSet
  var testing: TestingSet
  let trainingStart = 4 + n
  for i in 0 ..< n:
    for j in 0 ..< dimension:
      let value = input[trainingStart + i * dimension + j]
      if value < -4 or value > 4: return -1
      training[i][j] = float64(value)
  let testingStart = trainingStart + n * dimension
  for i in 0 ..< queryCount:
    for j in 0 ..< dimension:
      let value = input[testingStart + i * dimension + j]
      if value < -4 or value > 4: return -1
      testing[i][j] = float64(value)
  fitPredict(labels, training, testing, n, dimension, queryCount, kind)
