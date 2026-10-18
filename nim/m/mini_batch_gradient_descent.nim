import math

const MaxSamples = 8
const MaxFeatures = 3
const MaxInput = 101

proc finite(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc mini_batch_gradient_descent*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "mini_batch_gradient_descent".} =
  if input == nil or inputLength < 5 or inputLength > MaxInput: return -1
  for i in 0 ..< 4:
    if not finite(input[i]) or input[i] != floor(input[i]): return -1
  if input[0] < 1 or input[0] > MaxSamples or input[1] < 1 or input[1] > MaxFeatures: return -1
  let samples = int(input[0])
  let features = int(input[1])
  if input[2] < 1 or input[2] > float64(samples) or input[3] < 0 or input[3] > 8: return -1
  let batchSize = int(input[2])
  let epochs = int(input[3])
  let learningRate = input[4]
  if not finite(learningRate) or learningRate < 0 or learningRate > 0.25: return -1
  let matrixStart = 5
  let targetsStart = matrixStart + samples * features
  let permutationsStart = targetsStart + samples
  if inputLength != csize_t(permutationsStart + epochs * samples): return -1

  var matrix: array[MaxSamples * MaxFeatures, float64]
  var targets: array[MaxSamples, float64]
  for i in 0 ..< samples * features:
    let value = input[matrixStart + i]
    if not finite(value) or abs(value) > 10: return -1
    matrix[i] = value
  for i in 0 ..< samples:
    let value = input[targetsStart + i]
    if not finite(value) or abs(value) > 100: return -1
    targets[i] = value
  var permutations: array[8 * 8, int]
  for epoch in 0 ..< epochs:
    var seen: array[MaxSamples, bool]
    for position in 0 ..< samples:
      let raw = input[permutationsStart + epoch * samples + position]
      if not finite(raw) or raw != floor(raw) or raw < 0 or raw >= float64(samples): return -1
      let sample = int(raw)
      if seen[sample]: return -1
      seen[sample] = true
      permutations[epoch * samples + position] = sample

  var weights: array[MaxFeatures, float64]
  var bias = 0.0
  for epoch in 0 ..< epochs:
    var start = 0
    while start < samples:
      let batchLength = min(batchSize, samples - start)
      var errors: array[MaxSamples, float64]
      for position in 0 ..< batchLength:
        let sample = permutations[epoch * samples + start + position]
        var prediction = 0.0
        for feature in 0 ..< features:
          prediction += matrix[sample * features + feature] * weights[feature]
          if not finite(prediction): return -1
        prediction += bias
        let error = prediction - targets[sample]
        if not finite(prediction) or not finite(error): return -1
        errors[position] = error
      for feature in 0 ..< features:
        var gradient = 0.0
        for position in 0 ..< batchLength:
          let sample = permutations[epoch * samples + start + position]
          gradient += matrix[sample * features + feature] * errors[position]
          if not finite(gradient): return -1
        let update = (learningRate * gradient) / float64(batchLength)
        weights[feature] -= update
        if not finite(update) or not finite(weights[feature]): return -1
      var errorSum = 0.0
      for position in 0 ..< batchLength:
        errorSum += errors[position]
        if not finite(errorSum): return -1
      let meanError = errorSum / float64(batchLength)
      let biasUpdate = learningRate * meanError
      bias -= biasUpdate
      if not finite(meanError) or not finite(biasUpdate) or not finite(bias): return -1
      start += batchLength

  var staged: array[MaxFeatures + 1, float64]
  for feature in 0 ..< features: staged[feature] = weights[feature]
  staged[features] = bias
  if output == nil or capacity < csize_t(features + 1): return -2
  for i in 0 ..< features + 1: output[i] = staged[i]
  int64(features + 1)
