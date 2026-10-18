import std/math

const MaxInputLength = 56
const MaxMapSize = 4
const MaxFeatureCount = 3

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc kohonen_som_topology*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "kohonen_som_topology".} =
  if input == nil or inputLength < 4 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, MaxMapSize) or
      not exactInteger(input[1], 1, MaxFeatureCount) or
      not exactInteger(input[2], 0, 8) or not exactInteger(input[3], 1, 16): return -1
  let mapSize = int(input[0])
  let featureCount = int(input[1])
  let radius = int(input[2])
  let alphaCode = int(input[3])
  let cellCount = mapSize * mapSize
  let weightCount = cellCount * featureCount
  if inputLength != csize_t(4 + featureCount + weightCount): return -1

  var sample: array[MaxFeatureCount, float64]
  for feature in 0 ..< featureCount:
    if not exactInteger(input[csize_t(4 + feature)], -8, 8): return -1
    sample[feature] = input[csize_t(4 + feature)]
  var weights: array[48, float64]
  for index in 0 ..< weightCount:
    let value = input[csize_t(4 + featureCount + index)]
    if not exactInteger(value, -8, 8): return -1
    weights[index] = value

  var bestMatchingUnit = 0
  var bestDistanceSquared = 0.0
  for feature in 0 ..< featureCount:
    let difference = weights[feature] - sample[feature]
    bestDistanceSquared += difference * difference
  var bestDistance = sqrt(bestDistanceSquared)
  for cell in 1 ..< cellCount:
    var distanceSquared = 0.0
    for feature in 0 ..< featureCount:
      let difference = weights[cell * featureCount + feature] - sample[feature]
      distanceSquared += difference * difference
    let distance = sqrt(distanceSquared)
    if distance < bestDistance:
      bestDistance = distance
      bestMatchingUnit = cell

  let bestX = bestMatchingUnit div mapSize
  let bestY = bestMatchingUnit mod mapSize
  let firstX = if bestX > radius: bestX - radius else: 0
  let afterX = min(mapSize, bestX + radius + 1)
  let firstY = if bestY > radius: bestY - radius else: 0
  let afterY = min(mapSize, bestY + radius + 1)
  let alpha = float64(alphaCode) / 16.0
  for x in firstX ..< afterX:
    for y in firstY ..< afterY:
      let dx = abs(bestX - x)
      let dy = abs(bestY - y)
      let gridDistanceSquared = float64(dx * dx + dy * dy)
      let scale = exp(-gridDistanceSquared / (2.0 * alpha * alpha))
      for feature in 0 ..< featureCount:
        let index = (x * mapSize + y) * featureCount + feature
        let difference = sample[feature] - weights[index]
        weights[index] += alpha * scale * difference
        if classify(weights[index]) in {fcNan, fcInf, fcNegInf}: return -1

  let outputLength = 1 + weightCount
  if output == nil or capacity < csize_t(outputLength): return -2
  output[0] = bestDistance
  for index in 0 ..< weightCount: output[index + 1] = weights[index]
  int64(outputLength)
