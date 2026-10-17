import std/math

const MaxPoints = 16
const MaxDimension = 3
const MaxInputLength = 54
const Margin = 1.0e-6

proc distance(a, b: openArray[float64], aStart, bStart, dimensions: int): float64 =
  var sum = 0.0
  for d in 0 ..< dimensions:
    let difference = a[aStart + d] - b[bStart + d]
    sum += difference * difference
  pow(sum, 0.5)
proc near(value, threshold: float64): bool = abs(value - threshold) < Margin

proc mean_shift*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mean_shift".} =
  if input.isNil or inputLength < csize_t(5) or inputLength > csize_t(MaxInputLength): return -1
  let length = int(inputLength)
  for i in 0 ..< length:
    if classify(input[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let nValue = input[0]; let dimensionValue = input[1]; let bandwidth = input[2]
  let iterationValue = input[3]; let tolerance = input[4]
  if nValue != trunc(nValue) or dimensionValue != trunc(dimensionValue) or iterationValue != trunc(iterationValue): return -1
  if nValue < 1.0 or nValue > MaxPoints.float64 or dimensionValue < 1.0 or dimensionValue > MaxDimension.float64 or
      iterationValue < 1.0 or iterationValue > 64.0 or bandwidth < 0.5 or bandwidth > 20.0 or tolerance < 1.0e-5 or tolerance > 1.0e-2: return -1
  let n = int(nValue); let dimensions = int(dimensionValue); let maxIterations = int(iterationValue)
  if length != 5 + n * dimensions: return -1
  var data: array[MaxPoints * MaxDimension, float64]
  for i in 0 ..< n * dimensions:
    if input[5 + i] < -10.0 or input[5 + i] > 10.0: return -1
    data[i] = input[5 + i]
  var candidates, next, centroids: array[MaxPoints * MaxDimension, float64]
  for i in 0 ..< n * dimensions: candidates[i] = data[i]
  for _ in 0 ..< maxIterations:
    for c in 0 ..< n:
      var sums: array[MaxDimension, float64]
      var neighbors = 0
      for p in 0 ..< n:
        let dist = distance(data, candidates, p * dimensions, c * dimensions, dimensions)
        if near(dist, bandwidth): return -1
        if dist <= bandwidth:
          inc neighbors
          for d in 0 ..< dimensions: sums[d] += data[p * dimensions + d]
      for d in 0 ..< dimensions:
        next[c * dimensions + d] = if neighbors == 0: candidates[c * dimensions + d] else: sums[d] / float64(neighbors)
    var allConverged = true
    for c in 0 ..< n:
      let movement = distance(candidates, next, c * dimensions, c * dimensions, dimensions)
      if near(movement, tolerance): return -1
      if movement >= tolerance:
        allConverged = false
        break
    if allConverged: break
    for i in 0 ..< n * dimensions: candidates[i] = next[i]
  var centroidCount = 0
  for c in 0 ..< n:
    var keep = true
    for existing in 0 ..< centroidCount:
      let dist = distance(candidates, centroids, c * dimensions, existing * dimensions, dimensions)
      if near(dist, bandwidth): return -1
      if dist < bandwidth:
        keep = false
        break
    if keep:
      for d in 0 ..< dimensions: centroids[centroidCount * dimensions + d] = candidates[c * dimensions + d]
      inc centroidCount
  var labels: array[MaxPoints, float64]
  for p in 0 ..< n:
    var bestIndex = 0
    var bestDistance = distance(data, centroids, p * dimensions, 0, dimensions)
    for c in 1 ..< centroidCount:
      let dist = distance(data, centroids, p * dimensions, c * dimensions, dimensions)
      if dist != bestDistance and near(dist, bestDistance): return -1
      if dist < bestDistance:
        bestIndex = c
        bestDistance = dist
    labels[p] = float64(bestIndex)
  if output.isNil or outputCapacity < csize_t(n): return -2
  for i in 0 ..< n: output[i] = labels[i]
  int64(n)
