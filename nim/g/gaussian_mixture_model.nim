import std/math

const
  MaxSamples = 16
  MaxInputLength = 19
  Pi = 3.14159265358979323846264338327950288

proc gaussianMixturePdf(value, mean, variance: float64): float64 =
  let difference = value - mean
  exp(-(difference * difference) / (2.0 * variance)) / sqrt(2.0 * Pi * variance)

proc gaussian_mixture_model*(values: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gaussian_mixture_model".} =
  if values == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let countValue = values[0]
  let maxIterations = values[1]
  let toleranceMicro = values[2]
  if countValue < 2 or countValue > MaxSamples or maxIterations < 1 or maxIterations > 20 or
      toleranceMicro < 1 or toleranceMicro > 1000: return -1
  let count = int(countValue)
  if int(length) != 3 + count: return -1
  var data: array[MaxSamples, float64]
  var previousSample = -5001'i64
  for index in 0 ..< count:
    let sample = values[3 + index]
    if sample < -5000 or sample > 5000 or sample < previousSample: return -1
    previousSample = sample
    data[index] = float64(sample) / 1000.0
  let required = count + 1
  if output == nil or capacity < csize_t(required): return -2

  var dataMean = 0.0
  for index in 0 ..< count: dataMean += data[index]
  dataMean /= float64(count)
  var variance = 0.0
  for index in 0 ..< count:
    let difference = data[index] - dataMean
    variance += difference * difference
  variance = variance / float64(count - 1) + 1e-6

  var weights: array[2, float64] = [0.5, 0.5]
  var means: array[2, float64] = [data[0], data[count - 1]]
  var variances: array[2, float64] = [variance, variance]
  var responsibilities: array[2, array[MaxSamples, float64]]
  let tolerance = float64(toleranceMicro) / 1_000_000.0
  var previousLikelihood = 0.0
  var hasPreviousLikelihood = false
  var iterations = 0

  for iteration in 0 ..< int(maxIterations):
    var componentCounts: array[2, float64]
    for index in 0 ..< count:
      let probability0 = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0])
      let probability1 = weights[1] * gaussianMixturePdf(data[index], means[1], variances[1])
      let total = probability0 + probability1
      if total == 0.0: return -1
      responsibilities[0][index] = probability0 / total
      responsibilities[1][index] = probability1 / total
      componentCounts[0] += responsibilities[0][index]
      componentCounts[1] += responsibilities[1][index]
    if componentCounts[0] <= 0.0 or componentCounts[1] <= 0.0: return -1

    for component in 0 ..< 2:
      weights[component] = componentCounts[component] / float64(count)
      var weightedSum = 0.0
      for index in 0 ..< count:
        weightedSum += responsibilities[component][index] * data[index]
      means[component] = weightedSum / componentCounts[component]
      var covariance = 0.0
      for index in 0 ..< count:
        let difference = data[index] - means[component]
        covariance += responsibilities[component][index] * difference * difference
      variances[component] = covariance / componentCounts[component] + 1e-6

    var likelihood = 0.0
    for index in 0 ..< count:
      let density = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0]) +
                    weights[1] * gaussianMixturePdf(data[index], means[1], variances[1])
      likelihood += ln(density + 1e-12)
    iterations = iteration + 1
    if hasPreviousLikelihood and abs(likelihood - previousLikelihood) < tolerance: break
    previousLikelihood = likelihood
    hasPreviousLikelihood = true

  output[0] = uint8(iterations)
  for index in 0 ..< count:
    let probability0 = weights[0] * gaussianMixturePdf(data[index], means[0], variances[0])
    let probability1 = weights[1] * gaussianMixturePdf(data[index], means[1], variances[1])
    output[index + 1] = (if probability0 >= probability1: 0'u8 else: 1'u8)
  int64(required)
