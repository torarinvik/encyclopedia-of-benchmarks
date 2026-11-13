type
  CpmtPoint = object
    x, y: int64
  CpmtInput = ptr UncheckedArray[int64]

const
  MinVertices = 3
  MaxVertices = 12
  MaxParseableLength = 26
  CoordLimit = 1000'i64

proc cross(a, b, c: CpmtPoint): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc squaredLength(points: array[MaxVertices, CpmtPoint], left, right: int): int64 =
  let dx = points[left].x - points[right].x
  let dy = points[left].y - points[right].y
  dx * dx + dy * dy

proc convex_polygon_minimax_length_triangulation*(input: CpmtInput, length: csize_t): int64
    {.cdecl, exportc: "convex_polygon_minimax_length_triangulation".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if input[0] < MinVertices.int64 or input[0] > MaxVertices.int64: return -1
  let n = int(input[0])
  if int(length) != 1 + 2 * n: return -1
  var points: array[MaxVertices, CpmtPoint]
  for i in 0 ..< n:
    points[i] = CpmtPoint(x: input[1 + 2 * i], y: input[2 + 2 * i])
    if points[i].x < -CoordLimit or points[i].x > CoordLimit or
        points[i].y < -CoordLimit or points[i].y > CoordLimit: return -1
  var area2 = 0'i64
  for i in 0 ..< n:
    let next = (i + 1) mod n
    area2 += points[i].x * points[next].y - points[i].y * points[next].x
  if area2 == 0: return -1
  let orientation = if area2 > 0: 1'i64 else: -1'i64
  for edge in 0 ..< n:
    let next = (edge + 1) mod n
    for vertex in 0 ..< n:
      if vertex != edge and vertex != next and
          orientation * cross(points[edge], points[next], points[vertex]) <= 0: return -1

  var best: array[MaxVertices * MaxVertices, int64]
  for left in 0 ..< n - 1:
    best[left * MaxVertices + left + 1] = squaredLength(points, left, left + 1)
  for span in 2 ..< n:
    for left in 0 ..< n - span:
      let right = left + span
      let boundary = squaredLength(points, left, right)
      var optimum = 8_000_001'i64
      for middle in left + 1 ..< right:
        let candidate = max(max(best[left * MaxVertices + middle], best[middle * MaxVertices + right]), boundary)
        optimum = min(optimum, candidate)
      best[left * MaxVertices + right] = optimum
  best[n - 1]
