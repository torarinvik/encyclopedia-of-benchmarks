import std/math

const
  MinCompression = 10
  MaxCompression = 20
  MaxSamples = 32
  MaxQueries = 4
  MaxInputLength = 45
  MaxValidInputLength = 44
  MaxOutputLength = 10
  TwoPi = 2.0 * PI

proc quantileLimit(compression, q: float64): float64 =
  var bounded = q
  if bounded < 0.0: bounded = 0.0
  if bounded > 1.0: bounded = 1.0
  let k = compression / TwoPi * arcsin(2.0 * bounded - 1.0) + 1.0
  let angle = k * TwoPi / compression
  if angle >= PI / 2.0: return 1.0
  if angle <= -PI / 2.0: return 0.0
  (sin(angle) + 1.0) / 2.0

proc interpolate(x0, y0, x1, y1, x: float64): float64 =
  if x1 <= x0: return y1
  y0 + (x - x0) / (x1 - x0) * (y1 - y0)

proc tdigest*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tdigest".} =
  if input == nil or inputLength < 7 or inputLength > MaxInputLength: return -1
  for i in 0 ..< int(inputLength):
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1

  let compressionValue = input[0]
  let sampleCountValue = input[1]
  if compressionValue != floor(compressionValue) or compressionValue < MinCompression or compressionValue > MaxCompression or
      sampleCountValue != floor(sampleCountValue) or sampleCountValue < 1 or sampleCountValue > MaxSamples:
    return -1
  let compression = int(compressionValue)
  let sampleCount = int(sampleCountValue)
  let quantileCountIndex = 2 + sampleCount
  if int(inputLength) <= quantileCountIndex: return -1
  let quantileCountValue = input[quantileCountIndex]
  if quantileCountValue != floor(quantileCountValue) or quantileCountValue < 1 or quantileCountValue > MaxQueries: return -1
  let quantileCount = int(quantileCountValue)
  let quantileStart = quantileCountIndex + 1
  let cdfCountIndex = quantileStart + quantileCount
  if int(inputLength) <= cdfCountIndex: return -1
  let cdfCountValue = input[cdfCountIndex]
  if cdfCountValue != floor(cdfCountValue) or cdfCountValue < 1 or cdfCountValue > MaxQueries: return -1
  let cdfCount = int(cdfCountValue)
  let cdfStart = cdfCountIndex + 1
  if int(inputLength) != cdfStart + cdfCount or int(inputLength) > MaxValidInputLength: return -1

  var samples: array[MaxSamples, float64]
  for i in 0 ..< sampleCount:
    let value = input[2 + i]
    if value < -8.0 or value > 8.0 or value != floor(value): return -1
    samples[i] = value
  var probabilities: array[MaxQueries, float64]
  for i in 0 ..< quantileCount:
    let value = input[quantileStart + i]
    if value < 0.0 or value > 1.0 or value * 4.0 != floor(value * 4.0): return -1
    probabilities[i] = value
  var cdfValues: array[MaxQueries, float64]
  for i in 0 ..< cdfCount:
    let value = input[cdfStart + i]
    if value < -8.0 or value > 8.0 or value != floor(value): return -1
    cdfValues[i] = value

  var sorted = samples
  for i in 1 ..< sampleCount:
    let value = sorted[i]
    var position = i
    while position > 0 and sorted[position - 1] > value:
      sorted[position] = sorted[position - 1]
      dec position
    sorted[position] = value

  var means: array[MaxSamples, float64]
  var weights: array[MaxSamples, float64]
  var centroidCount = 1
  means[0] = sorted[0]
  weights[0] = 1.0
  var closedWeight = 0.0
  let totalWeight = float64(sampleCount)
  var weightLimit = totalWeight * quantileLimit(float64(compression), 0.0)
  let centroidCapacity = 2 * (compression + 2)
  var last = 0
  for i in 1 ..< sampleCount:
    let projected = weights[last] + 1.0
    let roomLeft = closedWeight + projected <= weightLimit
    if roomLeft or last == centroidCapacity - 1:
      weights[last] = projected
      means[last] += (sorted[i] - means[last]) / projected
    else:
      closedWeight += weights[last]
      weightLimit = totalWeight * quantileLimit(float64(compression), closedWeight / totalWeight)
      inc last
      means[last] = sorted[i]
      weights[last] = 1.0
      inc centroidCount

  var staged: array[MaxOutputLength, float64]
  var outputIndex = 0
  staged[outputIndex] = float64(quantileCount)
  inc outputIndex
  let minimum = sorted[0]
  let maximum = sorted[sampleCount - 1]
  for query in 0 ..< quantileCount:
    let q = probabilities[query]
    var result: float64
    if centroidCount == 1:
      result = means[0]
    else:
      let index = q * totalWeight
      if index <= 0.0: result = minimum
      elif index >= totalWeight: result = maximum
      else:
        var previousValue = minimum
        var previousIndex = 0.0
        var currentIndex = 0.0
        var found = false
        for i in 0 ..< centroidCount:
          if i == 0: currentIndex += weights[i] / 2.0
          else: currentIndex += (weights[i - 1] + weights[i]) / 2.0
          if index < currentIndex:
            result = interpolate(previousIndex, previousValue, currentIndex, means[i], index)
            found = true
            break
          previousValue = means[i]
          previousIndex = currentIndex
        if not found: result = interpolate(previousIndex, previousValue, totalWeight, maximum, index)
    staged[outputIndex] = result
    inc outputIndex
  staged[outputIndex] = float64(cdfCount)
  inc outputIndex
  for query in 0 ..< cdfCount:
    let value = cdfValues[query]
    var result: float64
    if value < minimum: result = 0.0
    elif value > maximum: result = 1.0
    elif maximum <= minimum: result = 0.5
    else:
      var previousValue = minimum
      var previousIndex = 0.0
      var currentIndex = 0.0
      var found = false
      for i in 0 ..< centroidCount:
        if i == 0: currentIndex += weights[i] / 2.0
        else: currentIndex += (weights[i - 1] + weights[i]) / 2.0
        if value < means[i]:
          result = interpolate(previousValue, previousIndex, means[i], currentIndex, value) / totalWeight
          found = true
          break
        previousValue = means[i]
        previousIndex = currentIndex
      if not found: result = interpolate(previousValue, previousIndex, maximum, totalWeight, value) / totalWeight
    staged[outputIndex] = result
    inc outputIndex

  if output == nil or outputCapacity < csize_t(outputIndex): return -2
  for i in 0 ..< outputIndex: output[i] = staged[i]
  int64(outputIndex)
