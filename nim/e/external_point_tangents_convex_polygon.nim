const MaxVertices = 32
const MaxQueries = 16
const MaxInput = 99
const MaxCoordinate = 1000'i64

type Point = object
  x, y: int64

proc sub(a, b: Point): Point = Point(x: a.x - b.x, y: a.y - b.y)
proc cross(a, b: Point): int64 = a.x * b.y - a.y * b.x

proc validPolygon(p: ptr UncheckedArray[Point], n: int): bool =
  for i in 0 ..< n:
    let next = (i + 1) mod n
    if p[i].x == p[next].x and p[i].y == p[next].y: return false
    let edge = sub(p[next], p[i])
    for j in 0 ..< n:
      if j != i and j != next and cross(edge, sub(p[j], p[i])) <= 0: return false
  true

proc validQuery(p: ptr UncheckedArray[Point], n: int, q: Point): bool =
  var outside = false
  for i in 0 ..< n:
    let side = cross(sub(p[(i + 1) mod n], p[i]), sub(q, p[i]))
    if side == 0: return false
    if side < 0: outside = true
  outside

proc buildChain(chain: var array[MaxVertices, int], n, start, stop: int): int =
  var at = start
  while true:
    if result >= n: return 0
    chain[result] = at
    inc result
    if at == stop: return
    at = (at + 1) mod n

proc buildLayers(p: ptr UncheckedArray[Point], n: int,
                 lower: var array[MaxVertices, int], upper: var array[MaxVertices, int]): tuple[lowerLen, upperLen: int] =
  var minX = 0
  var maxX = 0
  for i in 1 ..< n:
    if p[i].x < p[minX].x: minX = i
    if p[i].x > p[maxX].x: maxX = i
  var leftBottom = minX
  var leftTop = minX
  var rightBottom = maxX
  var rightTop = maxX
  for i in 0 ..< n:
    if p[i].x == p[minX].x:
      if p[i].y < p[leftBottom].y: leftBottom = i
      if p[i].y > p[leftTop].y: leftTop = i
    if p[i].x == p[maxX].x:
      if p[i].y < p[rightBottom].y: rightBottom = i
      if p[i].y > p[rightTop].y: rightTop = i
  result.lowerLen = buildChain(lower, n, leftBottom, rightBottom)
  result.upperLen = buildChain(upper, n, rightTop, leftTop)

proc splitAscending(p: ptr UncheckedArray[Point], chain: ptr UncheckedArray[int], length: int, qx: int64): int =
  var lo = 0
  var hi = length
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if p[chain[mid]].x < qx: lo = mid + 1 else: hi = mid
  if lo == 0: 0 else: lo - 1

proc splitDescending(p: ptr UncheckedArray[Point], chain: ptr UncheckedArray[int], length: int, qx: int64): int =
  var lo = 0
  var hi = length
  while lo < hi:
    let mid = lo + (hi - lo) div 2
    if p[chain[mid]].x > qx: lo = mid + 1 else: hi = mid
  if lo == 0: 0 else: lo - 1

proc tangentSearch(p: ptr UncheckedArray[Point], n: int, chain: ptr UncheckedArray[int],
                   first, last: int, q: Point, sign: int64): int =
  var lo = first
  var hi = last
  result = lo
  while lo <= hi:
    let mid = lo + (hi - lo) div 2
    let index = chain[mid]
    let here = sub(p[index], q)
    let toNext = sign * cross(here, sub(p[(index + 1) mod n], q))
    let toPrev = sign * cross(here, sub(p[(index + n - 1) mod n], q))
    if toNext >= 0 and toPrev >= 0: return mid
    if toNext >= 0:
      result = mid
      hi = mid - 1
    else:
      lo = mid + 1

proc supports(p: ptr UncheckedArray[Point], n, index: int, q: Point, sign: int64): bool =
  let here = sub(p[index], q)
  sign * cross(here, sub(p[(index + n - 1) mod n], q)) > 0 and
    sign * cross(here, sub(p[(index + 1) mod n], q)) > 0

proc findTangents(p: ptr UncheckedArray[Point], n: int, lowerPtr, upperPtr: ptr UncheckedArray[int],
                  lowerLen, upperLen: int, q: Point): tuple[ok: bool, first, second: int] =
  let lowerSplit = splitAscending(p, lowerPtr, lowerLen, q.x)
  let upperSplit = splitDescending(p, upperPtr, upperLen, q.x)
  let leftA = lowerPtr[tangentSearch(p, n, lowerPtr, 0, lowerSplit, q, -1)]
  let leftB = upperPtr[tangentSearch(p, n, upperPtr, 0, upperSplit, q, -1)]
  let rightA = lowerPtr[tangentSearch(p, n, lowerPtr, lowerSplit, lowerLen - 1, q, 1)]
  let rightB = upperPtr[tangentSearch(p, n, upperPtr, upperSplit, upperLen - 1, q, 1)]
  var left = -1
  var right = -1
  if supports(p, n, leftA, q, -1): left = leftA
  elif supports(p, n, leftB, q, -1): left = leftB
  if supports(p, n, rightA, q, 1): right = rightA
  elif supports(p, n, rightB, q, 1): right = rightB
  if left < 0 or right < 0 or left == right: return (false, -1, -1)
  if left < right: (true, left, right) else: (true, right, left)

proc putI64(outBytes: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    outBytes[offset] = uint8((bits shr (8 * b)) and 255)
    inc offset

proc external_point_tangents_convex_polygon*(values: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "external_point_tangents_convex_polygon".} =
  if values.isNil or n < 2 or n > csize_t(MaxInput): return -1
  if values[0] < 3 or values[0] > MaxVertices or values[1] < 0 or values[1] > MaxQueries: return -1
  let vertices = int(values[0])
  let queries = int(values[1])
  if int(n) != 2 + 2 * vertices + 2 * queries: return -1
  var polygon: array[MaxVertices, Point]
  var queryPoints: array[MaxQueries, Point]
  var answers: array[2 * MaxQueries, int64]
  var at = 2
  for i in 0 ..< vertices:
    polygon[i] = Point(x: values[at], y: values[at + 1])
    at += 2
    if polygon[i].x < -MaxCoordinate or polygon[i].x > MaxCoordinate or
       polygon[i].y < -MaxCoordinate or polygon[i].y > MaxCoordinate: return -1
  let polygonPtr = cast[ptr UncheckedArray[Point]](addr polygon[0])
  if not validPolygon(polygonPtr, vertices): return -1
  var lower, upper: array[MaxVertices, int]
  let layers = buildLayers(polygonPtr, vertices, lower, upper)
  if layers.lowerLen == 0 or layers.upperLen == 0: return -1
  let lowerPtr = cast[ptr UncheckedArray[int]](addr lower[0])
  let upperPtr = cast[ptr UncheckedArray[int]](addr upper[0])
  for i in 0 ..< queries:
    queryPoints[i] = Point(x: values[at], y: values[at + 1])
    at += 2
    if queryPoints[i].x < -MaxCoordinate or queryPoints[i].x > MaxCoordinate or
       queryPoints[i].y < -MaxCoordinate or queryPoints[i].y > MaxCoordinate or
       not validQuery(polygonPtr, vertices, queryPoints[i]): return -1
    let found = findTangents(polygonPtr, vertices, lowerPtr, upperPtr,
      layers.lowerLen, layers.upperLen, queryPoints[i])
    if not found.ok: return -1
    answers[2 * i] = int64(found.first)
    answers[2 * i + 1] = int64(found.second)
  let needed = 16 * queries
  if csize_t(needed) > capacity or output.isNil: return -2
  var offset = 0
  for i in 0 ..< 2 * queries: putI64(output, offset, answers[i])
  int64(needed)
