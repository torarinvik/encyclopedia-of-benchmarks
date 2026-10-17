import std/math

const MaxInputLength = 84

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc k_means_clust*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "k_means_clust".} =
  if input == nil or inputLength < 3 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, 16) or not exactInteger(input[1], 1, 4) or not exactInteger(input[2], 1, 4): return -1
  let pointCount = int(input[0])
  let dimension = int(input[1])
  let clusterCount = int(input[2])
  if clusterCount > pointCount: return -1
  let dataStart = 3
  let centroidStart = dataStart + pointCount * dimension
  let expectedLength = centroidStart + clusterCount * dimension
  if inputLength != csize_t(expectedLength): return -1
  for i in dataStart ..< expectedLength:
    if not exactInteger(input[i], -16, 16): return -1

  var assignments: array[16, int]
  var counts: array[4, int]
  var sums: array[4, array[4, int64]]
  for point in 0 ..< pointCount:
    var bestCluster = 0
    var bestDistance = 0'i64
    for feature in 0 ..< dimension:
      let value = int64(input[dataStart + point * dimension + feature])
      let center = int64(input[centroidStart + feature])
      let delta = value - center
      bestDistance += delta * delta
    for cluster in 1 ..< clusterCount:
      var distance = 0'i64
      for feature in 0 ..< dimension:
        let value = int64(input[dataStart + point * dimension + feature])
        let center = int64(input[centroidStart + cluster * dimension + feature])
        let delta = value - center
        distance += delta * delta
      if distance < bestDistance:
        bestDistance = distance
        bestCluster = cluster
    assignments[point] = bestCluster
    inc counts[bestCluster]
    for feature in 0 ..< dimension:
      sums[bestCluster][feature] += int64(input[dataStart + point * dimension + feature])
  for cluster in 0 ..< clusterCount:
    if counts[cluster] == 0: return -1
  let outputLength = pointCount + clusterCount * dimension
  if output == nil or capacity < csize_t(outputLength): return -2
  for point in 0 ..< pointCount: output[point] = float64(assignments[point])
  for cluster in 0 ..< clusterCount:
    for feature in 0 ..< dimension:
      output[pointCount + cluster * dimension + feature] = float64(sums[cluster][feature]) / float64(counts[cluster])
  int64(outputLength)
