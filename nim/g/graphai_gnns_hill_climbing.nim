const MaxN = 16
const MaxD = 4
const MaxInput = 89
const MaxParseable = 90
const CoordLimit = 100'i64
const DistanceRadix = 160001'i64

proc graphai_gnns_hill_climbing*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "graphai_gnns_hill_climbing".} =
  if input == nil or length < csize_t(5) or length > csize_t(MaxParseable):
    return -1
  let nValue = input[0]
  let dValue = input[1]
  let startValue = input[2]
  let eValue = input[3]
  let tValue = input[4]
  if nValue < 2 or nValue > MaxN or dValue < 1 or dValue > MaxD:
    return -1
  if startValue < 0 or startValue >= nValue or eValue < 1 or eValue >= nValue:
    return -1
  if tValue < 0 or tValue > 16:
    return -1
  let n = int(nValue)
  let d = int(dValue)
  if length != csize_t(5 + n * d + n + d) or length > csize_t(MaxInput):
    return -1

  var coordinates: array[MaxN * MaxD, int64]
  for index in 0 ..< n * d:
    let coordinate = input[5 + index]
    if coordinate < -CoordLimit or coordinate > CoordLimit:
      return -1
    coordinates[index] = coordinate
  let maskOffset = 5 + n * d
  let allowed = (1'i64 shl n) - 1
  var masks: array[MaxN, int64]
  for vertex in 0 ..< n:
    let mask = input[maskOffset + vertex]
    if mask < 0 or (mask and not allowed) != 0 or (mask and (1'i64 shl vertex)) != 0:
      return -1
    masks[vertex] = mask
  var query: array[MaxD, int64]
  for axis in 0 ..< d:
    let coordinate = input[maskOffset + n + axis]
    if coordinate < -CoordLimit or coordinate > CoordLimit:
      return -1
    query[axis] = coordinate

  var current = int(startValue)
  var currentDistance = 0'i64
  for axis in 0 ..< d:
    let delta = coordinates[current * d + axis] - query[axis]
    currentDistance += delta * delta
  var evaluations = 1'i64
  var moves = 0'i64
  for _ in 0 ..< int(tValue):
    var bestVertex = current
    var bestDistance = currentDistance
    var inspected = 0'i64
    for vertex in 0 ..< n:
      if (masks[current] and (1'i64 shl vertex)) == 0:
        continue
      var distance = 0'i64
      for axis in 0 ..< d:
        let delta = coordinates[vertex * d + axis] - query[axis]
        distance += delta * delta
      inc evaluations
      inc inspected
      if distance < bestDistance or (distance == bestDistance and vertex < bestVertex):
        bestVertex = vertex
        bestDistance = distance
      if inspected == eValue:
        break
    if bestDistance >= currentDistance:
      break
    current = bestVertex
    currentDistance = bestDistance
    inc moves
  (((evaluations * 17 + moves) * 16 + int64(current)) * DistanceRadix + currentDistance)
