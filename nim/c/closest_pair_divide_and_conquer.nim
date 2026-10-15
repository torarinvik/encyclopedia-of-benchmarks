## Deterministic closest pair with x-rank divide-and-conquer and a y-ordered strip.
const MaxPoints = 1024

type
  Point = object
    x, y: int64
  PointArray = array[MaxPoints, Point]
  IndexArray = array[MaxPoints, int]
  PairResult = object
    valid: bool
    distanceSquared: uint64
    first, second: int

proc before(left, right: int, points: var PointArray, byY: bool): bool =
  if byY:
    if points[left].y != points[right].y: return points[left].y < points[right].y
    if points[left].x != points[right].x: return points[left].x < points[right].x
  else:
    if points[left].x != points[right].x: return points[left].x < points[right].x
    if points[left].y != points[right].y: return points[left].y < points[right].y
  left < right

proc sortIndices(indices, scratch: var IndexArray, beginIndex, endIndex: int,
    points: var PointArray, byY: bool) =
  if endIndex - beginIndex < 2: return
  let middle = beginIndex + (endIndex - beginIndex) div 2
  sortIndices(indices, scratch, beginIndex, middle, points, byY)
  sortIndices(indices, scratch, middle, endIndex, points, byY)
  var left = beginIndex
  var right = middle
  var output = beginIndex
  while left < middle and right < endIndex:
    if before(indices[right], indices[left], points, byY):
      scratch[output] = indices[right]
      inc right
    else:
      scratch[output] = indices[left]
      inc left
    inc output
  while left < middle:
    scratch[output] = indices[left]
    inc left
    inc output
  while right < endIndex:
    scratch[output] = indices[right]
    inc right
    inc output
  for index in beginIndex ..< endIndex:
    indices[index] = scratch[index]

proc squaredDistance(left, right: int, points: var PointArray): uint64 =
  let dx = points[left].x - points[right].x
  let dy = points[left].y - points[right].y
  uint64(dx * dx) + uint64(dy * dy)

proc choose(left, right: PairResult): PairResult =
  if not left.valid: return right
  if not right.valid: return left
  if left.distanceSquared < right.distanceSquared: return left
  if right.distanceSquared < left.distanceSquared: return right
  if left.first < right.first or (left.first == right.first and left.second <= right.second): return left
  right

proc candidate(left, right: int, points: var PointArray): PairResult =
  var first = left
  var second = right
  if first > second: swap(first, second)
  PairResult(valid: true, distanceSquared: squaredDistance(first, second, points), first: first, second: second)

proc search(xOrder: var IndexArray, beginIndex, endIndex: int,
    yOrder: var IndexArray, yCount: int, rank: var IndexArray,
    points: var PointArray): PairResult =
  let count = endIndex - beginIndex
  if count <= 3:
    var best = PairResult(valid: false)
    for i in beginIndex ..< endIndex:
      for j in i + 1 ..< endIndex:
        best = choose(best, candidate(xOrder[i], xOrder[j], points))
    return best

  let middle = beginIndex + count div 2
  var yLeft, yRight: IndexArray
  var leftCount = 0
  var rightCount = 0
  for i in 0 ..< yCount:
    let point = yOrder[i]
    if rank[point] < middle:
      yLeft[leftCount] = point
      inc leftCount
    else:
      yRight[rightCount] = point
      inc rightCount
  var best = choose(
    search(xOrder, beginIndex, middle, yLeft, leftCount, rank, points),
    search(xOrder, middle, endIndex, yRight, rightCount, rank, points))

  var strip: IndexArray
  var stripCount = 0
  let middleX = points[xOrder[middle]].x
  for i in 0 ..< yCount:
    let point = yOrder[i]
    let dx = points[point].x - middleX
    if uint64(dx * dx) <= best.distanceSquared:
      strip[stripCount] = point
      inc stripCount
  for i in 0 ..< stripCount:
    for j in i + 1 ..< stripCount:
      let dy = points[strip[j]].y - points[strip[i]].y
      if uint64(dy * dy) > best.distanceSquared: break
      best = choose(best, candidate(strip[i], strip[j], points))
  best

proc writePair(output: ptr UncheckedArray[uint8], pair: PairResult) =
  for byte in 0 ..< 4:
    output[byte] = uint8((uint32(pair.first) shr (8 * byte)) and 0xFF'u32)
    output[4 + byte] = uint8((uint32(pair.second) shr (8 * byte)) and 0xFF'u32)

proc closest_pair_divide_and_conquer*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "closest_pair_divide_and_conquer".} =
  if length > 2 * MaxPoints or length mod 2 != 0 or (length != 0 and values == nil): return -1
  let pointCount = int(length div 2)

  var points: PointArray
  var xOrder, yOrder, rank, scratch: IndexArray
  for i in 0 ..< pointCount:
    let x = values[2 * i]
    let y = values[2 * i + 1]
    if x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000: return -1
    points[i] = Point(x: x, y: y)
    xOrder[i] = i
    yOrder[i] = i
  if pointCount < 2: return 0
  sortIndices(xOrder, scratch, 0, pointCount, points, false)
  for i in 0 ..< pointCount:
    rank[xOrder[i]] = i

  var duplicate = PairResult(valid: false)
  var groupBegin = 0
  while groupBegin < pointCount:
    var groupEnd = groupBegin + 1
    let anchor = xOrder[groupBegin]
    while groupEnd < pointCount and points[xOrder[groupEnd]].x == points[anchor].x and
        points[xOrder[groupEnd]].y == points[anchor].y:
      inc groupEnd
    if groupEnd - groupBegin > 1:
      var first = MaxPoints
      var second = MaxPoints
      for i in groupBegin ..< groupEnd:
        let id = xOrder[i]
        if id < first:
          second = first
          first = id
        elif id < second:
          second = id
      duplicate = choose(duplicate, PairResult(valid: true, distanceSquared: 0, first: first, second: second))
    groupBegin = groupEnd
  if duplicate.valid:
    if output == nil or outputCapacity < 8: return -2
    writePair(output, duplicate)
    return 2

  sortIndices(yOrder, scratch, 0, pointCount, points, true)
  let best = search(xOrder, 0, pointCount, yOrder, pointCount, rank, points)
  if not best.valid: return -1
  if output == nil or outputCapacity < 8: return -2
  writePair(output, best)
  2
