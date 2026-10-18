import std/math

const InvalidResult = -1.0e300
const MaxInputLength = 144
const MaxRows = 32
const MaxDimensions = 4
const MaxClusters = 8
const MaxIterations = 64

proc kmeans_raw_r*(input: ptr UncheckedArray[int64], inputLength: csize_t): float64
    {.cdecl, exportc: "kmeans_raw_r".} =
  if input.isNil or inputLength < 12 or inputLength > MaxInputLength.csize_t:
    return InvalidResult
  let rowsValue = input[0]
  let dimensionsValue = input[1]
  let clustersValue = input[2]
  let iterationLimitValue = input[3]
  if rowsValue < 2 or rowsValue > MaxRows or dimensionsValue < 2 or dimensionsValue > MaxDimensions or
      clustersValue < 1 or clustersValue > MaxClusters or clustersValue > rowsValue div 2 or
      iterationLimitValue < 1 or iterationLimitValue > MaxIterations:
    return InvalidResult

  let rows = int(rowsValue)
  let dimensions = int(dimensionsValue)
  let clusters = int(clustersValue)
  let iterationLimit = int(iterationLimitValue)
  let dataCount = rows * dimensions
  let dataStart = 4 + clusters
  let selectorStart = dataStart + dataCount
  if int(inputLength) != selectorStart + 3:
    return InvalidResult

  var data: array[MaxRows * MaxDimensions, float64]
  for cluster in 0 ..< clusters:
    let initialRow = input[4 + cluster]
    if initialRow < 0 or initialRow >= rowsValue:
      return InvalidResult
    for earlier in 0 ..< cluster:
      if input[4 + earlier] == initialRow:
        return InvalidResult
  for index in 0 ..< dataCount:
    let coordinate = input[dataStart + index]
    if coordinate < -64 or coordinate > 64:
      return InvalidResult
    data[index] = float64(coordinate)

  let field = input[selectorStart]
  let arg0 = input[selectorStart + 1]
  let arg1 = input[selectorStart + 2]
  if field < 0 or field > 2:
    return InvalidResult
  if field == 0 and (arg0 < 0 or arg0 >= clustersValue or arg1 < 0 or arg1 >= dimensionsValue):
    return InvalidResult
  if field == 1 and (arg0 < 0 or arg0 >= rowsValue or arg1 < 0 or arg1 >= clustersValue):
    return InvalidResult
  if field == 2 and (arg0 < 0 or arg0 >= rowsValue or arg1 != 0):
    return InvalidResult

  var centers: array[MaxClusters * MaxDimensions, float64]
  for cluster in 0 ..< clusters:
    let initialRow = int(input[4 + cluster])
    for dimension in 0 ..< dimensions:
      centers[cluster * dimensions + dimension] = data[initialRow * dimensions + dimension]

  var distances: array[MaxRows * MaxClusters, float64]
  var assignments: array[MaxRows, int]
  var stable = false
  for iteration in 0 ..< iterationLimit:
    var memberCounts: array[MaxClusters, int]
    for row in 0 ..< rows:
      var bestCluster = 0
      for cluster in 0 ..< clusters:
        var squaredDistance = 0.0
        for dimension in 0 ..< dimensions:
          let difference = data[row * dimensions + dimension] - centers[cluster * dimensions + dimension]
          squaredDistance += difference * difference
        distances[row * clusters + cluster] = sqrt(squaredDistance)
        if cluster > 0 and distances[row * clusters + cluster] < distances[row * clusters + bestCluster]:
          bestCluster = cluster
      assignments[row] = bestCluster
      inc memberCounts[bestCluster]
    for cluster in 0 ..< clusters:
      if memberCounts[cluster] < 2:
        return InvalidResult

    var updated: array[MaxClusters * MaxDimensions, float64]
    for row in 0 ..< rows:
      let cluster = assignments[row]
      for dimension in 0 ..< dimensions:
        updated[cluster * dimensions + dimension] += data[row * dimensions + dimension]
    stable = true
    for cluster in 0 ..< clusters:
      for dimension in 0 ..< dimensions:
        let index = cluster * dimensions + dimension
        updated[index] /= float64(memberCounts[cluster])
        if updated[index] != centers[index]:
          stable = false
    for index in 0 ..< clusters * dimensions:
      centers[index] = updated[index]
    if stable:
      break
  if not stable:
    return InvalidResult

  let index0 = int(arg0)
  let index1 = int(arg1)
  if field == 0:
    return centers[index0 * dimensions + index1]
  if field == 1:
    return distances[index0 * clusters + index1]
  float64(assignments[index0])
