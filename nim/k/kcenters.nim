const
  MaxPoints = 8
  MaxDistance = 1_000_000
  MaxPointsI64 = int64(MaxPoints)
  MaxDistanceI64 = int64(MaxDistance)
  JavaIntMax = 2_147_483_647'i64
  MaxInputLength = 2 + MaxPoints * MaxPoints

proc kcenters*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kcenters".} =
  if values == nil or length < 2 or length > MaxInputLength: return -1
  let pointCount = values[0]
  let centerCount = values[1]
  if pointCount < 1 or pointCount > MaxPointsI64 or centerCount < 1 or centerCount > pointCount: return -1
  if length != csize_t(2 + pointCount * pointCount): return -1
  for row in 0 ..< int(pointCount):
    for column in 0 ..< int(pointCount):
      let distance = values[2 + row * int(pointCount) + column]
      if distance < 0 or distance > MaxDistanceI64 or (row == column and distance != 0): return -1
      if distance != values[2 + column * int(pointCount) + row]: return -1

  var selected: array[MaxPoints, bool]
  var maxDistance: array[MaxPoints, int64]
  for point in 0 ..< int(pointCount): maxDistance[point] = JavaIntMax
  selected[0] = true
  for point in 1 ..< int(pointCount):
    let distance = values[2 + point]
    if distance < maxDistance[point]: maxDistance[point] = distance
  for center in 1 ..< int(centerCount):
    var farthest = -1
    for point in 0 ..< int(pointCount):
      if not selected[point] and (farthest == -1 or maxDistance[point] > maxDistance[farthest]): farthest = point
    selected[farthest] = true
    for point in 0 ..< int(pointCount):
      let distance = values[2 + farthest * int(pointCount) + point]
      if distance < maxDistance[point]: maxDistance[point] = distance
  var result = 0'i64
  for point in 0 ..< int(pointCount):
    if maxDistance[point] > result: result = maxDistance[point]
  result
