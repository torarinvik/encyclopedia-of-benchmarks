const MaxVertices = 32
const MaxQueries = 32
const MaxInput = 131
const MaxCoord = 1_000_000'i64

type Point = object
  x, y: int64

proc sub(a, b: Point): Point = Point(x: a.x - b.x, y: a.y - b.y)
proc cross(a, b: Point): int64 = a.x * b.y - a.y * b.x
proc onSegment(a, b, p: Point): bool =
  let edge = sub(b, a)
  let rel = sub(p, a)
  cross(edge, rel) == 0 and p.x >= min(a.x, b.x) and p.x <= max(a.x, b.x)
    and p.y >= min(a.y, b.y) and p.y <= max(a.y, b.y)
proc validPolygon(p: ptr UncheckedArray[Point], n: int): bool =
  for i in 0 ..< n:
    let next = (i + 1) mod n
    if p[i].x == p[next].x and p[i].y == p[next].y: return false
    let edge = sub(p[next], p[i])
    for j in 0 ..< n:
      if j != i and j != next and cross(edge, sub(p[j], p[i])) <= 0: return false
    for j in i + 1 ..< n:
      if p[i].x == p[j].x and p[i].y == p[j].y: return false
  true
proc containsFan(fan: ptr UncheckedArray[Point], m: int, query: Point): int64 =
  let origin = Point(x: 0, y: 0)
  let first = cross(fan[0], query)
  let last = cross(fan[m - 1], query)
  if first < 0 or last > 0: return 0
  if first == 0: return int64(onSegment(origin, fan[0], query))
  if last == 0: return int64(onSegment(origin, fan[m - 1], query))
  var lo = 0
  var hi = m
  while hi - lo > 1:
    let mid = (lo + hi) div 2
    if cross(fan[mid], query) >= 0: lo = mid else: hi = mid
  let side = cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]))
  if side < 0: return 0
  if side == 0: return int64(onSegment(fan[lo], fan[lo + 1], query))
  1
proc putI64(outBytes: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    outBytes[offset] = uint8((bits shr (8 * b)) and 255)
    inc offset

proc point_in_convex_polygon_log_query*(values: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_in_convex_polygon_log_query".} =
  if values.isNil or n < 2 or n > csize_t(MaxInput): return -1
  if values[0] < 3 or values[0] > MaxVertices or values[1] < 0 or values[1] > MaxQueries: return -1
  let vertices = int(values[0])
  let queries = int(values[1])
  if int(n) != 2 + 2 * vertices + 2 * queries: return -1
  var polygon: array[MaxVertices, Point]
  var fan: array[MaxVertices, Point]
  var queryPoints: array[MaxQueries, Point]
  var answers: array[MaxQueries, int64]
  var at = 2
  for i in 0 ..< vertices:
    polygon[i] = Point(x: values[at], y: values[at + 1])
    at += 2
    if polygon[i].x < -MaxCoord or polygon[i].x > MaxCoord or polygon[i].y < -MaxCoord or polygon[i].y > MaxCoord: return -1
  if not validPolygon(cast[ptr UncheckedArray[Point]](addr polygon[0]), vertices): return -1
  for i in 0 ..< queries:
    queryPoints[i] = Point(x: values[at], y: values[at + 1])
    at += 2
    if queryPoints[i].x < -MaxCoord or queryPoints[i].x > MaxCoord or queryPoints[i].y < -MaxCoord or queryPoints[i].y > MaxCoord: return -1
  var pivot = 0
  for i in 1 ..< vertices:
    if polygon[i].x < polygon[pivot].x or (polygon[i].x == polygon[pivot].x and polygon[i].y < polygon[pivot].y): pivot = i
  for i in 0 ..< vertices - 1:
    fan[i] = sub(polygon[(pivot + i + 1) mod vertices], polygon[pivot])
  for i in 0 ..< queries:
    answers[i] = containsFan(cast[ptr UncheckedArray[Point]](addr fan[0]), vertices - 1,
      sub(queryPoints[i], polygon[pivot]))
  let needed = 8 * queries
  if csize_t(needed) > capacity or (needed > 0 and output.isNil): return -2
  var offset = 0
  for i in 0 ..< queries: putI64(output, offset, answers[i])
  int64(needed)
