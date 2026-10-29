const MaxPoints = 32
const MaxInputLength = 1 + 2 * MaxPoints
const CoordinateLimit = 1_000_000'i64

proc manhattan_mst*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "manhattan_mst".} =
  if values == nil or length < 1 or length > MaxInputLength.csize_t:
    return -1
  let countValue = values[0]
  if countValue < 1 or countValue > MaxPoints.int64:
    return -1
  let count = int(countValue)
  if int(length) != 1 + 2 * count:
    return -1

  var x: array[MaxPoints, int64]
  var y: array[MaxPoints, int64]
  for point in 0 ..< count:
    x[point] = values[1 + 2 * point]
    y[point] = values[2 + 2 * point]
    if x[point] < -CoordinateLimit or x[point] > CoordinateLimit or
        y[point] < -CoordinateLimit or y[point] > CoordinateLimit:
      return -1

  var inTree: array[MaxPoints, bool]
  var hasBest: array[MaxPoints, bool]
  var best: array[MaxPoints, int64]
  hasBest[0] = true
  var total = 0'i64
  for _ in 0 ..< count:
    var selected = count
    for point in 0 ..< count:
      if not inTree[point] and hasBest[point] and
          (selected == count or best[point] < best[selected]):
        selected = point
    if selected == count:
      return -1
    inTree[selected] = true
    total += best[selected]
    for point in 0 ..< count:
      if inTree[point]:
        continue
      let dx = x[selected] - x[point]
      let dy = y[selected] - y[point]
      let distance = (if dx < 0: -dx else: dx) + (if dy < 0: -dy else: dy)
      if not hasBest[point] or distance < best[point]:
        hasBest[point] = true
        best[point] = distance
  total
