const MaxPoints = 1024

type
  Point = object
    x, y: int64
    id: int
  PointArray = array[MaxPoints, Point]
  IndexArray = array[MaxPoints, int]

proc cross(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc radiusSquared(pivot, point: Point): int64 =
  let dx = point.x - pivot.x
  let dy = point.y - pivot.y
  dx * dx + dy * dy

proc beforeX(left, right: int, points: var PointArray): bool =
  if points[left].x != points[right].x: return points[left].x < points[right].x
  if points[left].y != points[right].y: return points[left].y < points[right].y
  points[left].id < points[right].id

proc beforeAngle(left, right: int, points: var PointArray, pivotIndex: int): bool =
  let pivot = points[pivotIndex]
  let turn = cross(pivot, points[left], points[right])
  if turn != 0: return turn > 0
  let leftRadius = radiusSquared(pivot, points[left])
  let rightRadius = radiusSquared(pivot, points[right])
  if leftRadius != rightRadius: return leftRadius < rightRadius
  points[left].id < points[right].id

proc sortIndices(items: var IndexArray, scratch: var IndexArray, beginIndex, endIndex: int,
    points: var PointArray, pivotIndex: int, byAngle: bool) =
  if endIndex - beginIndex < 2: return
  let middle = beginIndex + (endIndex - beginIndex) div 2
  sortIndices(items, scratch, beginIndex, middle, points, pivotIndex, byAngle)
  sortIndices(items, scratch, middle, endIndex, points, pivotIndex, byAngle)
  var left = beginIndex
  var right = middle
  var outputIndex = beginIndex
  while left < middle and right < endIndex:
    let rightFirst = if byAngle:
      beforeAngle(items[right], items[left], points, pivotIndex)
    else:
      beforeX(items[right], items[left], points)
    if rightFirst:
      scratch[outputIndex] = items[right]
      inc right
    else:
      scratch[outputIndex] = items[left]
      inc left
    inc outputIndex
  while left < middle:
    scratch[outputIndex] = items[left]
    inc left
    inc outputIndex
  while right < endIndex:
    scratch[outputIndex] = items[right]
    inc right
    inc outputIndex
  for index in beginIndex ..< endIndex: items[index] = scratch[index]

proc writeIndex(output: ptr UncheckedArray[uint8], position, id: int) =
  let value = uint32(id)
  for byte in 0 ..< 4:
    output[4 * position + byte] = uint8((value shr (8 * byte)) and 0xFF'u32)

proc convex_hull_graham_scan*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "convex_hull_graham_scan".} =
  if length > 2 * MaxPoints or length mod 2 != 0 or (length != 0 and values == nil): return -1
  let pointCount = int(length div 2)
  var inputPoints: PointArray
  var points: PointArray
  var order, scratch, hull: IndexArray
  for index in 0 ..< pointCount:
    let x = values[2 * index]
    let y = values[2 * index + 1]
    if x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000: return -1
    inputPoints[index] = Point(x: x, y: y, id: index)
    order[index] = index
  if pointCount == 0: return 0
  sortIndices(order, scratch, 0, pointCount, inputPoints, 0, false)
  var uniqueCount = 0
  for index in 0 ..< pointCount:
    let point = inputPoints[order[index]]
    if uniqueCount == 0 or points[uniqueCount - 1].x != point.x or points[uniqueCount - 1].y != point.y:
      points[uniqueCount] = point
      inc uniqueCount
  if uniqueCount == 1:
    if output == nil or outputCapacity < 4: return -2
    writeIndex(output, 0, points[0].id)
    return 1
  var pivot = 0
  for index in 1 ..< uniqueCount:
    if points[index].y < points[pivot].y or
        (points[index].y == points[pivot].y and points[index].x < points[pivot].x): pivot = index
    order[index] = index
  order[0] = 0
  sortIndices(order, scratch, 0, uniqueCount, points, pivot, true)
  var allCollinear = true
  for index in 2 ..< uniqueCount:
    if cross(points[pivot], points[order[1]], points[order[index]]) != 0: allCollinear = false
  if not allCollinear:
    var rayBegin = uniqueCount - 1
    while rayBegin > 1 and cross(points[pivot], points[order[rayBegin - 1]], points[order[uniqueCount - 1]]) == 0:
      dec rayBegin
    var left = rayBegin
    var right = uniqueCount - 1
    while left < right:
      swap(order[left], order[right])
      inc left
      dec right
  var hullCount = 0
  for index in 0 ..< uniqueCount:
    let point = order[index]
    while hullCount >= 2 and cross(points[hull[hullCount - 2]], points[hull[hullCount - 1]], points[point]) < 0:
      dec hullCount
    hull[hullCount] = point
    inc hullCount
  if output == nil or outputCapacity < csize_t(4 * hullCount): return -2
  for index in 0 ..< hullCount: writeIndex(output, index, points[hull[index]].id)
  int64(hullCount)
