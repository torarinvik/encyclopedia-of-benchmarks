import std/math

const MaxSamples = 32
const MaxFeatures = 8
const QScale = 1_000_000.0
const InvalidResult = -1.0e300

proc logistic_regression_csharp_binary_gd*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "logistic_regression_csharp_binary_gd".} =
  if input.isNil or length < 4: return InvalidResult
  let mValue = input[0]
  let dValue = input[1]
  let epochsValue = input[2]
  let rateQ = input[3]
  if mValue < 1 or mValue > MaxSamples or dValue < 1 or dValue > MaxFeatures
      or epochsValue < 0 or epochsValue > 128 or rateQ < 1 or rateQ > 100_000: return InvalidResult
  let m = int(mValue)
  let d = int(dValue)
  let epochs = int(epochsValue)
  let labelsOffset = 4 + m * d
  let queryOffset = labelsOffset + m
  if int(length) != queryOffset + d: return InvalidResult
  for index in 0 ..< m * d:
    if input[4 + index] < -1_000_000 or input[4 + index] > 1_000_000: return InvalidResult
  for sample in 0 ..< m:
    if input[labelsOffset + sample] != 0 and input[labelsOffset + sample] != 1: return InvalidResult
  for feature in 0 ..< d:
    if input[queryOffset + feature] < -1_000_000 or input[queryOffset + feature] > 1_000_000: return InvalidResult

  var weights: array[MaxFeatures, float64]
  var gradient: array[MaxFeatures, float64]
  var bias = 0.0
  let learningRate = float64(rateQ) / QScale
  for epoch in 0 ..< epochs:
    for feature in 0 ..< d: gradient[feature] = 0.0
    var biasGradient = 0.0
    for sample in 0 ..< m:
      var dot = 0.0
      for feature in 0 ..< d:
        let x = float64(input[4 + sample * d + feature]) / QScale
        dot += x * weights[feature]
      let linear = dot + bias
      let prediction = 1.0 / (1.0 + exp(-linear))
      let error = prediction - float64(input[labelsOffset + sample])
      for feature in 0 ..< d:
        let x = float64(input[4 + sample * d + feature]) / QScale
        gradient[feature] += error * x
      biasGradient += error
    for feature in 0 ..< d:
      weights[feature] -= learningRate * gradient[feature] / float64(m)
    bias -= learningRate * biasGradient / float64(m)

  var queryDot = 0.0
  for feature in 0 ..< d:
    let x = float64(input[queryOffset + feature]) / QScale
    queryDot += x * weights[feature]
  let queryLinear = queryDot + bias
  1.0 / (1.0 + exp(-queryLinear))
