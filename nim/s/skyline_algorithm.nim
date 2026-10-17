const MaxPoints = 64
const MaxInputLength = 130
const MaxOutputBytes = 513

type Point = object
  x: int32
  y: int32

proc dominates(left, right: Point): bool =
  (left.x < right.x and left.y <= right.y) or
    (left.x <= right.x and left.y < right.y)

proc produceSkyline(points: array[MaxPoints, Point], start, count: int,
    output: var array[MaxPoints, Point]): int =
  if count == 1:
    output[0] = points[start]
    return 1
  if count == 2:
    if dominates(points[start], points[start + 1]):
      output[0] = points[start]
      return 1
    if dominates(points[start + 1], points[start]):
      output[0] = points[start + 1]
      return 1
    output[0] = points[start]
    output[1] = points[start + 1]
    return 2

  let middle = count div 2
  var left, right: array[MaxPoints, Point]
  var leftCount = produceSkyline(points, start, middle, left)
  var rightCount = produceSkyline(points, start + middle, count - middle, right)
  var index = 0
  while index + 1 < leftCount:
    if left[index].x == left[index + 1].x and left[index].y > left[index + 1].y:
      for move in index ..< leftCount - 1:
        left[move] = left[move + 1]
      dec leftCount
      if index > 0: dec index
    else:
      inc index

  var minimumY = left[0].y
  index = 1
  while index < leftCount:
    if minimumY > left[index].y:
      minimumY = left[index].y
      if minimumY == 1: break
    inc index

  index = 0
  while index < rightCount:
    if right[index].y >= minimumY:
      for move in index ..< rightCount - 1:
        right[move] = right[move + 1]
      dec rightCount
    else:
      inc index
  for item in 0 ..< leftCount: output[item] = left[item]
  for item in 0 ..< rightCount: output[leftCount + item] = right[item]
  leftCount + rightCount

proc skyline_algorithm*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "skyline_algorithm".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxPoints.int64: return -1
  let count = int(countValue)
  if inputLength != csize_t(1 + 2 * count): return -1

  var points: array[MaxPoints, Point]
  for index in 0 ..< count:
    let x = input[1 + 2 * index]
    let y = input[2 + 2 * index]
    if x < low(int32).int64 or x > high(int32).int64 or y < 1 or y > high(int32).int64:
      return -1
    if index > 0 and x <= input[1 + 2 * (index - 1)]: return -1
    points[index] = Point(x: int32(x), y: int32(y))

  var skyline: array[MaxPoints, Point]
  let skylineCount = produceSkyline(points, 0, count, skyline)
  var staged: array[MaxOutputBytes, uint8]
  staged[0] = uint8(skylineCount)
  for index in 0 ..< skylineCount:
    let offset = 1 + 8 * index
    let xBits = cast[uint32](skyline[index].x)
    let yBits = cast[uint32](skyline[index].y)
    for byte in 0 ..< 4:
      staged[offset + byte] = uint8((xBits shr (8 * byte)) and 0xff'u32)
      staged[offset + 4 + byte] = uint8((yBits shr (8 * byte)) and 0xff'u32)
  let written = 1 + 8 * skylineCount
  if output == nil or outputCapacity < csize_t(written): return -2
  for index in 0 ..< written: output[index] = staged[index]
  int64(written)
