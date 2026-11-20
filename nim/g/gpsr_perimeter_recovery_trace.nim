const
  MaxN = 8
  MaxM = 18
  MaxPath = 37
  MaxInput = 57
  MaxOutput = 896
  MaxOutputWords = 112

type
  Point = object
    x, y: int64
  Edge = object
    u, v: int

proc cross(ax, ay, bx, by: int64): int64 =
  ax * by - ay * bx

proc orient(a, b, c: Point): int64 =
  cross(b.x - a.x, b.y - a.y, c.x - a.x, c.y - a.y)

proc halfPlane(x, y: int64): int =
  if y > 0 or (y == 0 and x >= 0): 0 else: 1

proc angleLess(ax, ay: int64, ai: int, bx, by: int64, bi: int): bool =
  let ah = halfPlane(ax, ay)
  let bh = halfPlane(bx, by)
  if ah != bh: return ah < bh
  let turn = cross(ax, ay, bx, by)
  if turn != 0: return turn > 0
  ai < bi

proc properCrossing(p, q, a, b: Point, num, den: var int64): bool =
  let rx = q.x - p.x
  let ry = q.y - p.y
  let sx = b.x - a.x
  let sy = b.y - a.y
  var d = cross(rx, ry, sx, sy)
  if d == 0: return false
  let ax = a.x - p.x
  let ay = a.y - p.y
  var tn = cross(ax, ay, sx, sy)
  var un = cross(ax, ay, rx, ry)
  if d < 0:
    d = -d
    tn = -tn
    un = -un
  if not (tn > 0 and tn < d and un > 0 and un < d): return false
  var x = tn
  var y = d
  while y != 0:
    let r = x mod y
    x = y
    y = r
  num = tn div x
  den = d div x
  true

proc segmentsCross(a, b, c, d: Point): bool =
  orient(a, b, c) * orient(a, b, d) < 0 and
    orient(c, d, a) * orient(c, d, b) < 0

proc edgeId(u, v, m: int, edges: array[MaxM, Edge]): int =
  let lo = min(u, v)
  let hi = max(u, v)
  for i in 0 ..< m:
    if edges[i].u == lo and edges[i].v == hi: return i
  -1

proc nextCcw(node, incoming: int, degree: array[MaxN, int],
             rotation: array[MaxN, array[MaxN, int]]): int =
  for i in 0 ..< degree[node]:
    if rotation[node][i] == incoming:
      return rotation[node][(i + 1) mod degree[node]]
  -1

proc firstCcw(node, target, n: int, points: array[MaxN, Point],
              degree: array[MaxN, int], adjacency: array[MaxN, array[MaxN, int]]): int =
  let rx = points[target].x - points[node].x
  let ry = points[target].y - points[node].y
  var best = -1
  var bestX, bestY: int64
  for i in 0 ..< degree[node]:
    let v = adjacency[node][i]
    let dx = points[v].x - points[node].x
    let dy = points[v].y - points[node].y
    let vx = rx * dx + ry * dy
    let vy = cross(rx, ry, dx, dy)
    if best < 0 or angleLess(vx, vy, v, bestX, bestY, best):
      best = v
      bestX = vx
      bestY = vy
  best

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[position + byte] = uint8((bits shr (8 * byte)) and 255)

proc gpsr_perimeter_recovery_trace*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gpsr_perimeter_recovery_trace".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let source64 = input[2]
  let target64 = input[3]
  if n64 < 3 or n64 > int64(MaxN) or m64 < n64 - 1 or
      m64 > min(int64(MaxM), 3 * n64 - 6) or source64 < 0 or target64 < 0 or
      source64 >= n64 or target64 >= n64 or source64 == target64:
    return -1
  let n = int(n64)
  let m = int(m64)
  let source = int(source64)
  let target = int(target64)
  if int64(length) != int64(4 + 2 * n + 2 * m): return -1

  var points: array[MaxN, Point]
  for i in 0 ..< n:
    points[i] = Point(x: input[4 + i], y: input[4 + n + i])
    if points[i].x < -16 or points[i].x > 16 or points[i].y < -16 or points[i].y > 16:
      return -1
    for j in 0 ..< i:
      if points[i].x == points[j].x and points[i].y == points[j].y: return -1
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      for k in j + 1 ..< n:
        if orient(points[i], points[j], points[k]) == 0: return -1

  var edges: array[MaxM, Edge]
  var adjacency: array[MaxN, array[MaxN, int]]
  var degree: array[MaxN, int]
  let edgeStart = 4 + 2 * n
  for i in 0 ..< m:
    let u64 = input[edgeStart + 2 * i]
    let v64 = input[edgeStart + 2 * i + 1]
    if u64 < 0 or v64 >= n64 or u64 >= v64: return -1
    let u = int(u64)
    let v = int(v64)
    if i > 0 and (edges[i - 1].u > u or
        (edges[i - 1].u == u and edges[i - 1].v >= v)): return -1
    edges[i] = Edge(u: u, v: v)
    adjacency[u][degree[u]] = v
    adjacency[v][degree[v]] = u
    inc degree[u]
    inc degree[v]

  var reached: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  queue[0] = source
  reached[source] = true
  while head < tail:
    let u = queue[head]
    inc head
    for i in 0 ..< degree[u]:
      let v = adjacency[u][i]
      if not reached[v]:
        reached[v] = true
        queue[tail] = v
        inc tail
  for i in 0 ..< n:
    if not reached[i]: return -1

  for i in 0 ..< m:
    for j in i + 1 ..< m:
      let a = edges[i].u
      let b = edges[i].v
      let c = edges[j].u
      let d = edges[j].v
      if a != c and a != d and b != c and b != d and
          segmentsCross(points[a], points[b], points[c], points[d]): return -1

  let sx = points[source].x - points[target].x
  let sy = points[source].y - points[target].y
  let sourceDistance = sx * sx + sy * sy
  for i in 0 ..< degree[source]:
    let v = adjacency[source][i]
    let dx = points[v].x - points[target].x
    let dy = points[v].y - points[target].y
    if dx * dx + dy * dy < sourceDistance: return -1
  if output.isNil or capacity < csize_t(MaxOutput): return -2

  var rotation: array[MaxN, array[MaxN, int]]
  for u in 0 ..< n:
    for i in 0 ..< degree[u]: rotation[u][i] = adjacency[u][i]
    for i in 1 ..< degree[u]:
      let v = rotation[u][i]
      let dx = points[v].x - points[u].x
      let dy = points[v].y - points[u].y
      var j = i
      while j > 0:
        let w = rotation[u][j - 1]
        if not angleLess(dx, dy, v, points[w].x - points[u].x,
                         points[w].y - points[u].y, w): break
        rotation[u][j] = w
        dec j
      rotation[u][j] = v

  var path: array[MaxPath, int]
  var events: array[MaxM, array[4, int64]]
  var pathCount = 1
  var crossingCount = 0
  var current = source
  var previous = -1
  var e0u = -1
  var e0v = -1
  var lfNum: int64 = 0
  var lfDen: int64 = 1
  var status: int64 = 0
  path[0] = source

  while true:
    let dx = points[current].x - points[target].x
    let dy = points[current].y - points[target].y
    if current == target:
      status = 2
      break
    if dx * dx + dy * dy < sourceDistance:
      status = 1
      break
    if pathCount - 1 >= 2 * m:
      status = 0
      break

    var candidate = if previous < 0:
      firstCcw(current, target, n, points, degree, adjacency)
    else:
      nextCcw(current, previous, degree, rotation)
    if candidate < 0:
      status = 0
      break
    var changedFace = false
    var invalidState = false
    while true:
      var tNum: int64
      var tDen: int64
      if not properCrossing(points[source], points[target], points[current],
                           points[candidate], tNum, tDen) or
          tNum * lfDen <= lfNum * tDen:
        break
      let crossingEdge = edgeId(current, candidate, m, edges)
      if crossingCount >= MaxM or crossingEdge < 0:
        status = 0
        invalidState = true
        break
      events[crossingCount] = [int64(pathCount - 1), int64(crossingEdge), tNum, tDen]
      inc crossingCount
      lfNum = tNum
      lfDen = tDen
      changedFace = true
      candidate = nextCcw(current, candidate, degree, rotation)
      if candidate < 0:
        status = 0
        invalidState = true
        break
    if invalidState: break
    if candidate < 0 or crossingCount > MaxM: break
    if changedFace or e0u < 0:
      e0u = current
      e0v = candidate
    elif e0u == current and e0v == candidate:
      status = 0
      break
    previous = current
    current = candidate
    if pathCount >= MaxPath:
      status = 0
      break
    path[pathCount] = current
    inc pathCount

  var words: array[MaxOutputWords, int64]
  var wordCount = 0
  words[wordCount] = status
  inc wordCount
  words[wordCount] = int64(pathCount - 1)
  inc wordCount
  for i in 0 ..< pathCount:
    words[wordCount] = int64(path[i])
    inc wordCount
  words[wordCount] = int64(crossingCount)
  inc wordCount
  for i in 0 ..< crossingCount:
    for j in 0 ..< 4:
      words[wordCount] = events[i][j]
      inc wordCount
  for i in 0 ..< wordCount: put64(output, 8 * i, words[i])
  int64(8 * wordCount)
