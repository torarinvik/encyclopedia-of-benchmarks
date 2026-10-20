const
  MaxPoints = 8
  MaxVertices = 11
  MaxWorkTriangles = 17
  MaxWorkEdges = 51
  MaxTriangles = 11
  MaxOutputBytes = 272
  CircumcircleEpsilon = 1e-4

type
  DelaunayPoint = object
    x, y: float64
  DelaunayEdge = object
    a, b: int
  DelaunayTriangle = object
    a, b, c: int
    cx, cy, radiusSquared: float64

proc orient(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

proc incircle(ax, ay, bx, by, cx, cy, dx, dy: int64): int64 =
  let x1 = ax - dx
  let y1 = ay - dy
  let x2 = bx - dx
  let y2 = by - dy
  let x3 = cx - dx
  let y3 = cy - dy
  let q1 = x1 * x1 + y1 * y1
  let q2 = x2 * x2 + y2 * y2
  let q3 = x3 * x3 + y3 * y3
  q1 * (x2 * y3 - y2 * x3) - q2 * (x1 * y3 - y1 * x3) + q3 * (x1 * y2 - y1 * x2)

proc sameEdge(a, b: DelaunayEdge): bool =
  (a.a == b.a and a.b == b.b) or (a.a == b.b and a.b == b.a)

proc makeTriangle(points: array[MaxVertices, DelaunayPoint], a, b, c: int): DelaunayTriangle =
  let p0 = points[a]
  let p1 = points[b]
  let p2 = points[c]
  let ax = p1.x - p0.x
  let ay = p1.y - p0.y
  let bx = p2.x - p0.x
  let by = p2.y - p0.y
  let m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y
  let u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y
  let scale = 1.0 / (2.0 * (ax * by - ay * bx))
  let cx = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale
  let cy = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale
  let dx = p0.x - cx
  let dy = p0.y - cy
  DelaunayTriangle(a: a, b: b, c: c, cx: cx, cy: cy, radiusSquared: dx * dx + dy * dy)

proc sortIndices(a, b, c: var int) =
  if a > b: swap(a, b)
  if b > c: swap(b, c)
  if a > b: swap(a, b)

proc triangleLess(a, b: DelaunayTriangle): bool =
  if a.a != b.a: return a.a < b.a
  if a.b != b.b: return a.b < b.b
  a.c < b.c

proc putI64(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc delaunay_triangulation*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "delaunay_triangulation".} =
  if values.isNil or length < csize_t(7) or length > csize_t(17): return -1
  if values[0] < 3 or values[0] > int64(MaxPoints): return -1
  let n = int(values[0])
  if length != csize_t(1 + 2 * n): return -1
  var ix: array[MaxPoints, int64]
  var iy: array[MaxPoints, int64]
  var points: array[MaxVertices, DelaunayPoint]
  var minX, maxX, minY, maxY: int64
  for i in 0 ..< n:
    let x = values[1 + 2 * i]
    let y = values[2 + 2 * i]
    if x < -10 or x > 10 or y < -10 or y > 10: return -1
    for j in 0 ..< i:
      if ix[j] == x and iy[j] == y: return -1
    ix[i] = x
    iy[i] = y
    points[i] = DelaunayPoint(x: float64(x), y: float64(y))
    if i == 0:
      minX = x; maxX = x; minY = y; maxY = y
    else:
      minX = min(minX, x); maxX = max(maxX, x)
      minY = min(minY, y); maxY = max(maxY, y)
  for a in 0 ..< n:
    for b in a + 1 ..< n:
      for c in b + 1 ..< n:
        if orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0: return -1
  for a in 0 ..< n:
    for b in a + 1 ..< n:
      for c in b + 1 ..< n:
        for d in c + 1 ..< n:
          if incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0: return -1

  let dx = maxX - minX
  let dy = maxY - minY
  let dmax = max(dx, dy)
  let midX = (float64(minX) + float64(maxX)) / 2.0
  let midY = (float64(minY) + float64(maxY)) / 2.0
  let s0 = n
  let s1 = n + 1
  let s2 = n + 2
  points[s0] = DelaunayPoint(x: midX - 20.0 * float64(dmax), y: midY - float64(dmax))
  points[s1] = DelaunayPoint(x: midX, y: midY + 20.0 * float64(dmax))
  points[s2] = DelaunayPoint(x: midX + 20.0 * float64(dmax), y: midY - float64(dmax))
  for a in 0 ..< n + 3:
    for b in a + 1 ..< n + 3:
      for c in b + 1 ..< n + 3:
        let area2 = (points[b].x - points[a].x) * (points[c].y - points[a].y) -
          (points[b].y - points[a].y) * (points[c].x - points[a].x)
        if area2 == 0.0: return -1

  var current: array[MaxWorkTriangles, DelaunayTriangle]
  var next: array[MaxWorkTriangles, DelaunayTriangle]
  var edges: array[MaxWorkEdges, DelaunayEdge]
  var currentCount = 1
  current[0] = makeTriangle(points, s0, s1, s2)
  for p in 0 ..< n:
    var edgeCount = 0
    var nextCount = 0
    for i in 0 ..< currentCount:
      let t = current[i]
      let vx = t.cx - points[p].x
      let vy = t.cy - points[p].y
      if vx * vx + vy * vy - t.radiusSquared <= CircumcircleEpsilon:
        edges[edgeCount] = DelaunayEdge(a: t.a, b: t.b)
        edges[edgeCount + 1] = DelaunayEdge(a: t.b, b: t.c)
        edges[edgeCount + 2] = DelaunayEdge(a: t.a, b: t.c)
        edgeCount += 3
      else:
        if nextCount >= MaxWorkTriangles: return -1
        next[nextCount] = t
        inc nextCount
    var remove: array[MaxWorkEdges, bool]
    for i in 0 ..< edgeCount:
      for j in 0 ..< edgeCount:
        if i != j and sameEdge(edges[i], edges[j]):
          remove[i] = true
          remove[j] = true
    for i in 0 ..< edgeCount:
      if not remove[i]:
        if nextCount >= MaxWorkTriangles: return -1
        next[nextCount] = makeTriangle(points, edges[i].a, edges[i].b, p)
        inc nextCount
    for i in 0 ..< nextCount: current[i] = next[i]
    currentCount = nextCount

  var result: array[MaxTriangles, DelaunayTriangle]
  var resultCount = 0
  for i in 0 ..< currentCount:
    var t = current[i]
    if t.a >= n or t.b >= n or t.c >= n: continue
    if resultCount >= MaxTriangles: return -1
    sortIndices(t.a, t.b, t.c)
    var j = resultCount
    inc resultCount
    while j > 0 and triangleLess(t, result[j - 1]):
      result[j] = result[j - 1]
      dec j
    result[j] = t
  if resultCount == 0: return -1
  var staged: array[MaxOutputBytes, uint8]
  putI64(staged, 0, int64(resultCount))
  for i in 0 ..< resultCount:
    putI64(staged, 8 + 24 * i, int64(result[i].a))
    putI64(staged, 16 + 24 * i, int64(result[i].b))
    putI64(staged, 24 + 24 * i, int64(result[i].c))
  let required = 8 + 24 * resultCount
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
