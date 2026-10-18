import math

const MaxSamples = 8
const MaxFeatures = 4
const MaxOutput = 34

proc finite(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc principal_component_analysis*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "principal_component_analysis".} =
  if input == nil or inputLength < 3 or inputLength > 35: return -1
  for i in 0 ..< 3:
    if not finite(input[i]) or input[i] != floor(input[i]): return -1
  if input[0] < 2 or input[0] > 8 or input[1] < 2 or input[1] > 4: return -1
  let samples = int(input[0])
  let features = int(input[1])
  if input[2] < 1 or input[2] > float64(features): return -1
  let components = int(input[2])
  if inputLength != csize_t(3 + samples * features): return -1

  var means: array[MaxFeatures, float64]
  var centered: array[MaxSamples * MaxFeatures, float64]
  for row in 0 ..< samples:
    for column in 0 ..< features:
      let value = input[3 + row * features + column]
      if not finite(value) or abs(value) > 100: return -1
      means[column] += value
      if not finite(means[column]): return -1
  for column in 0 ..< features:
    means[column] /= float64(samples)
    if not finite(means[column]): return -1
  for row in 0 ..< samples:
    for column in 0 ..< features:
      let value = input[3 + row * features + column] - means[column]
      if not finite(value): return -1
      centered[row * features + column] = value

  var matrix: array[16, float64]
  for i in 0 ..< features:
    for j in i ..< features:
      var covariance = 0.0
      for row in 0 ..< samples:
        covariance += centered[row * features + i] * centered[row * features + j]
        if not finite(covariance): return -1
      covariance /= float64(samples)
      if not finite(covariance): return -1
      matrix[i * features + j] = covariance
      matrix[j * features + i] = covariance

  var deflated = matrix
  var eigenvectors: array[16, float64]
  for component in 0 ..< components:
    var vector: array[MaxFeatures, float64]
    for i in 0 ..< features: vector[i] = 1.0
    var converged = false
    for iteration in 0 ..< 1000:
      let previous = vector
      var next: array[MaxFeatures, float64]
      for i in 0 ..< features:
        for j in 0 ..< features:
          next[i] += deflated[i * features + j] * vector[j]
          if not finite(next[i]): return -1
      var normSquared = 0.0
      for i in 0 ..< features:
        normSquared += next[i] * next[i]
        if not finite(normSquared): return -1
      let norm = sqrt(normSquared)
      if not finite(norm) or norm <= 1e-10: return -1
      for i in 0 ..< features:
        next[i] /= norm
        if not finite(next[i]): return -1
      var difference = 0.0
      for i in 0 ..< features:
        let change = abs(next[i] - previous[i])
        if not finite(change): return -1
        if change > difference: difference = change
      vector = next
      if difference < 1e-10:
        converged = true
        break
    if not converged: return -1

    var numerator = 0.0
    for i in 0 ..< features:
      var rowSum = 0.0
      for j in 0 ..< features:
        rowSum += deflated[i * features + j] * vector[j]
        if not finite(rowSum): return -1
      numerator += rowSum * vector[i]
      if not finite(numerator): return -1
    var denominator = 0.0
    for i in 0 ..< features:
      denominator += vector[i] * vector[i]
      if not finite(denominator): return -1
    if denominator == 0: return -1
    let eigenvalue = numerator / denominator
    if not finite(eigenvalue): return -1
    for i in 0 ..< features: eigenvectors[component * MaxFeatures + i] = vector[i]
    for i in 0 ..< features:
      for j in 0 ..< features:
        deflated[i * features + j] -= eigenvalue * vector[i] * vector[j]
        if not finite(deflated[i * features + j]): return -1

  var staged: array[MaxOutput, float64]
  staged[0] = float64(samples)
  staged[1] = float64(components)
  for row in 0 ..< samples:
    for component in 0 ..< components:
      var score = 0.0
      for column in 0 ..< features:
        score += eigenvectors[component * MaxFeatures + column] * centered[row * features + column]
        if not finite(score): return -1
      staged[2 + row * components + component] = score
  let outputSize = 2 + samples * components
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
