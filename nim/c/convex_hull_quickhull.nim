const MaxPoints = 1024

type
  Point = object
    x, y: int64
    id: int
  PointArray = array[MaxPoints, Point]
  BoolArray = array[MaxPoints, bool]

proc before(a, b: Point): bool =
  if a.x != b.x: return a.x < b.x
  if a.y != b.y: return a.y < b.y
  a.id < b.id

proc cross(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc sortPoints(points: var PointArray, scratch: var PointArray, beginIndex, endIndex: int) =
  if endIndex - beginIndex < 2: return
  let middle = beginIndex + (endIndex - beginIndex) div 2
  sortPoints(points, scratch, beginIndex, middle)
  sortPoints(points, scratch, middle, endIndex)
  var left = beginIndex
  var right = middle
  var outIndex = beginIndex
  while left < middle and right < endIndex:
    if before(points[right], points[left]):
      scratch[outIndex] = points[right]
      inc right
    else:
      scratch[outIndex] = points[left]
      inc left
    inc outIndex
  while left < middle:
    scratch[outIndex] = points[left]
    inc left
    inc outIndex
  while right < endIndex:
    scratch[outIndex] = points[right]
    inc right
    inc outIndex
  for index in beginIndex ..< endIndex: points[index] = scratch[index]

proc quickHull(points: var PointArray, count, left, right: int, onHull: var BoolArray) =
  var farthest = -1
  var greatestArea = 0'i64
  for index in 0 ..< count:
    let area = cross(points[left], points[right], points[index])
    if area > greatestArea:
      greatestArea = area
      farthest = index
  if farthest < 0: return
  onHull[farthest] = true
  quickHull(points, count, left, farthest, onHull)
  quickHull(points, count, farthest, right, onHull)

proc writeHull(points: var PointArray, count: int, onHull: var BoolArray,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 =
  var hullCount = 0
  for index in 0 ..< count:
    if onHull[index]: inc hullCount
  if output == nil or outputCapacity < csize_t(4 * hullCount): return -2
  var position = 0
  for index in 0 ..< count:
    if not onHull[index]: continue
    let id = uint32(points[index].id)
    for byte in 0 ..< 4:
      output[4 * position + byte] = uint8((id shr (8 * byte)) and 0xFF'u32)
    inc position
  int64(hullCount)

proc convex_hull_quickhull*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "convex_hull_quickhull".} =
  if length > 2 * MaxPoints or length mod 2 != 0 or (length != 0 and values == nil): return -1
  let inputCount = int(length div 2)
  var points, scratch: PointArray
  for index in 0 ..< inputCount:
    let x = values[2 * index]
    let y = values[2 * index + 1]
    if x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000: return -1
    points[index] = Point(x: x, y: y, id: index)
  if inputCount == 0: return 0
  sortPoints(points, scratch, 0, inputCount)
  var count = 0
  for index in 0 ..< inputCount:
    let point = points[index]
    if count == 0 or points[count - 1].x != point.x or points[count - 1].y != point.y:
      points[count] = point
      inc count
  var onHull: BoolArray
  if count == 1: onHull[0] = true
  else:
    onHull[0] = true
    onHull[count - 1] = true
    quickHull(points, count, 0, count - 1, onHull)
    quickHull(points, count, count - 1, 0, onHull)
  writeHull(points, count, onHull, output, outputCapacity)
