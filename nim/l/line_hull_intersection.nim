const MaxVertices = 16
const MaxParseableLength = 38
type Vector = tuple[x, y: int64]
type Point = tuple[x, y: int64]
type Hit = tuple[edge, numerator, denominator: int64]

proc polarHalf(v: Vector): int =
  if v.y > 0 or (v.y == 0 and v.x >= 0): 0 else: 1

proc angleBefore(a, b: Vector): bool =
  let ah = polarHalf(a)
  let bh = polarHalf(b)
  if ah != bh: return ah < bh
  a.x * b.y - a.y * b.x > 0

proc rotationMinimum(edges: array[MaxVertices, Vector], count: int): int =
  var low = 0
  var high = count - 1
  while low < high:
    let middle = (low + high) div 2
    if angleBefore(edges[middle], edges[high]): high = middle
    else: low = middle + 1
  low

proc supportEdge(edges: array[MaxVertices, Vector], count: int, target: Vector): int =
  let pivot = rotationMinimum(edges, count)
  var low = 0
  var high = count
  while low < high:
    let middle = (low + high) div 2
    if angleBefore(edges[(pivot + middle) mod count], target): low = middle + 1
    else: high = middle
  (pivot + low) mod count

proc lineValue(points: array[MaxVertices, Point], index: int,
               origin: Point, direction: Vector): int64 =
  direction.x * (points[index].y - origin.y) - direction.y * (points[index].x - origin.x)

proc lineParameter(point: Point, origin: Point, direction: Vector): int64 =
  (point.x - origin.x) * direction.x + (point.y - origin.y) * direction.y

proc crossing(points: array[MaxVertices, Point], count: int, origin: Point,
              direction: Vector, start, finish: int, increasing: bool): Hit =
  let span = (finish + count - start) mod count
  var low = 0
  var high = span
  while high - low > 1:
    let middle = (low + high) div 2
    let value = lineValue(points, (start + middle) mod count, origin, direction)
    if (increasing and value < 0) or (not increasing and value > 0): low = middle
    else: high = middle
  var index = (start + low) mod count
  if lineValue(points, (start + high) mod count, origin, direction) == 0:
    index = (start + high) mod count
  let value = lineValue(points, index, origin, direction)
  if value == 0:
    return (int64(index), lineParameter(points[index], origin, direction), 1'i64)
  let next = (index + 1) mod count
  let nextValue = lineValue(points, next, origin, direction)
  var denominator = value - nextValue
  let edgeDot = (points[next].x - points[index].x) * direction.x +
                (points[next].y - points[index].y) * direction.y
  var numerator = lineParameter(points[index], origin, direction) * denominator + value * edgeDot
  if denominator < 0:
    numerator = -numerator
    denominator = -denominator
  (int64(index), numerator, denominator)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc line_hull_intersection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "line_hull_intersection".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let countValue = input[0]
  if countValue < 3 or countValue > MaxVertices: return -1
  let count = int(countValue)
  if length != csize_t(5 + 2 * count): return -1
  let origin: Point = (input[1], input[2])
  let lineEnd: Point = (input[3], input[4])
  if origin.x < -50 or origin.x > 50 or origin.y < -50 or origin.y > 50 or
     lineEnd.x < -50 or lineEnd.x > 50 or lineEnd.y < -50 or lineEnd.y > 50: return -1
  let direction: Vector = (lineEnd.x - origin.x, lineEnd.y - origin.y)
  if direction.x == 0 and direction.y == 0: return -1

  var points: array[MaxVertices, Point]
  var edges: array[MaxVertices, Vector]
  for i in 0 ..< count:
    points[i] = (input[5 + 2 * i], input[6 + 2 * i])
    if points[i].x < -50 or points[i].x > 50 or points[i].y < -50 or points[i].y > 50: return -1
    for j in 0 ..< i:
      if points[j].x == points[i].x and points[j].y == points[i].y: return -1
  var area2 = 0'i64
  for i in 0 ..< count:
    let next = (i + 1) mod count
    edges[i] = (points[next].x - points[i].x, points[next].y - points[i].y)
    area2 += points[i].x * points[next].y - points[next].x * points[i].y
  if area2 <= 0: return -1
  for i in 0 ..< count:
    let next = (i + 1) mod count
    for j in 0 ..< count:
      if j == i or j == next: continue
      let side = edges[i].x * (points[j].y - points[i].y) - edges[i].y * (points[j].x - points[i].x)
      if side <= 0: return -1

  let maximum = supportEdge(edges, count, (-direction.x, -direction.y))
  let minimum = supportEdge(edges, count, direction)
  let maxValue = lineValue(points, maximum, origin, direction)
  let minValue = lineValue(points, minimum, origin, direction)
  var first = -1'i64
  var second = -1'i64
  if minValue > 0 or maxValue < 0:
    first = -1
    second = -1
  elif minValue == 0 or maxValue == 0:
    let touch = if minValue == 0: minimum else: maximum
    let next = (touch + 1) mod count
    let previous = (touch + count - 1) mod count
    if lineValue(points, touch, origin, direction) == 0 and lineValue(points, next, origin, direction) == 0:
      first = int64(touch); second = int64(touch)
    elif lineValue(points, previous, origin, direction) == 0 and lineValue(points, touch, origin, direction) == 0:
      first = int64(previous); second = int64(previous)
    else:
      first = int64(touch); second = -1
  else:
    let a = crossing(points, count, origin, direction, maximum, minimum, false)
    let b = crossing(points, count, origin, direction, minimum, maximum, true)
    if a.numerator * b.denominator <= b.numerator * a.denominator:
      first = a.edge; second = b.edge
    else:
      first = b.edge; second = a.edge
  if output == nil or capacity < 16: return -2
  storeI64Le(output, 0, first)
  storeI64Le(output, 8, second)
  16
