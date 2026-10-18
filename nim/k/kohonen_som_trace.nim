import std/math

const MaxInputLength = 41
const MaxNodeCount = 8
const MaxFeatureCount = 4

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc kohonen_som_trace*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "kohonen_som_trace".} =
  if input == nil or inputLength < 4 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, MaxNodeCount) or
      not exactInteger(input[1], 1, MaxFeatureCount) or
      not exactInteger(input[2], 0, 8) or not exactInteger(input[3], 1, 16): return -1
  let nodeCount = int(input[0])
  let featureCount = int(input[1])
  let radius = int(input[2])
  let alphaCode = int(input[3])
  let weightCount = nodeCount * featureCount
  if inputLength != csize_t(4 + featureCount + weightCount): return -1

  var sample: array[MaxFeatureCount, float64]
  for feature in 0 ..< featureCount:
    if not exactInteger(input[csize_t(4 + feature)], -8, 8): return -1
    sample[feature] = input[csize_t(4 + feature)]
  var weights: array[32, float64]
  for index in 0 ..< weightCount:
    let value = input[csize_t(4 + featureCount + index)]
    if not exactInteger(value, -8, 8): return -1
    weights[index] = value

  var bestMatchingUnit = 0
  var bestDistance = 0.0
  for feature in 0 ..< featureCount:
    let difference = weights[feature] - sample[feature]
    bestDistance += difference * difference
  for node in 1 ..< nodeCount:
    var distance = 0.0
    for feature in 0 ..< featureCount:
      let difference = weights[node * featureCount + feature] - sample[feature]
      distance += difference * difference
    if distance < bestDistance:
      bestDistance = distance
      bestMatchingUnit = node

  let firstNode = if bestMatchingUnit > radius: bestMatchingUnit - radius else: 0
  let afterLastNode = min(nodeCount, bestMatchingUnit + radius + 1)
  let alpha = float64(alphaCode) / 16.0
  for node in firstNode ..< afterLastNode:
    for feature in 0 ..< featureCount:
      let index = node * featureCount + feature
      let difference = sample[feature] - weights[index]
      weights[index] += alpha * difference
      if classify(weights[index]) in {fcNan, fcInf, fcNegInf}: return -1

  if output == nil or capacity < csize_t(weightCount): return -2
  for index in 0 ..< weightCount: output[index] = weights[index]
  int64(weightCount)
