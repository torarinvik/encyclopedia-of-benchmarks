const MaxN = 16
const MaxM = 42
const MaxInput = 118
const MaxCoord = 100'i64
type Point = tuple[x, y: int64]

proc orient(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc between(a, b, p: int64): bool =
  (a <= p and p <= b) or (b <= p and p <= a)

proc onSegment(a, b, p: Point): bool =
  between(a.x, b.x, p.x) and between(a.y, b.y, p.y)

proc intersects(a, b, c, d: Point): bool =
  let abC = orient(a, b, c)
  let abD = orient(a, b, d)
  let cdA = orient(c, d, a)
  let cdB = orient(c, d, b)
  (((abC > 0 and abD < 0) or (abC < 0 and abD > 0)) and
   ((cdA > 0 and cdB < 0) or (cdA < 0 and cdB > 0))) or
  (abC == 0 and onSegment(a, b, c)) or (abD == 0 and onSegment(a, b, d)) or
  (cdA == 0 and onSegment(c, d, a)) or (cdB == 0 and onSegment(c, d, b))

proc angleHalf(dx, dy: int64): int =
  if dy > 0 or (dy == 0 and dx >= 0): 0 else: 1

proc angleLess(a, b, origin: int, points: array[MaxN, Point]): bool =
  let ax = points[a].x - points[origin].x
  let ay = points[a].y - points[origin].y
  let bx = points[b].x - points[origin].x
  let by = points[b].y - points[origin].y
  let ah = angleHalf(ax, ay)
  let bh = angleHalf(bx, by)
  ah < bh or (ah == bh and ax * by - ay * bx > 0)

proc planar_face_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "planar_face_count".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxM): return -1
  let n = int(input[0])
  let m = int(input[1])
  let edgeCap = if n == 1: 0 elif n == 2: 1 else: 3 * n - 6
  if m > edgeCap or int(length) != 2 + 2 * n + 2 * m: return -1
  var points = default(array[MaxN, Point])
  for v in 0 ..< n:
    points[v] = (input[2 + 2 * v], input[3 + 2 * v])
    if points[v].x < -MaxCoord or points[v].x > MaxCoord or
       points[v].y < -MaxCoord or points[v].y > MaxCoord: return -1
    for prior in 0 ..< v:
      if points[v] == points[prior]: return -1

  var adjacent = default(array[MaxN * MaxN, bool])
  var neighbors = default(array[MaxN * MaxN, int])
  var degree = default(array[MaxN, int])
  var edgeU, edgeV: array[MaxM, int]
  let offset = 2 + 2 * n
  for e in 0 ..< m:
    let uValue = input[offset + 2 * e]
    let vValue = input[offset + 2 * e + 1]
    if uValue < 0 or uValue >= int64(n) or vValue < 0 or vValue >= int64(n) or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if adjacent[u * MaxN + v]: return -1
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    neighbors[u * MaxN + degree[u]] = v
    inc degree[u]
    neighbors[v * MaxN + degree[v]] = u
    inc degree[v]
    edgeU[e] = u
    edgeV[e] = v

  var reached = default(array[MaxN, bool])
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  reached[0] = true
  queue[0] = 0
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if adjacent[u * MaxN + v] and not reached[v]:
        reached[v] = true
        queue[tail] = v
        inc tail
  for v in 0 ..< n:
    if not reached[v]: return -1

  for i in 0 ..< m:
    for j in i + 1 ..< m:
      let u = edgeU[i]
      let v = edgeV[i]
      let a = edgeU[j]
      let b = edgeV[j]
      var common = -1
      if u == a or u == b: common = u
      if v == a or v == b:
        if common < 0: common = v
      if common >= 0:
        let p = if u == common: v else: u
        let q = if a == common: b else: a
        let ax = points[p].x - points[common].x
        let ay = points[p].y - points[common].y
        let bx = points[q].x - points[common].x
        let by = points[q].y - points[common].y
        if ax * by == ay * bx and ax * bx + ay * by > 0: return -1
      elif intersects(points[u], points[v], points[a], points[b]):
        return -1
  if n == 1: return 1

  for u in 0 ..< n:
    for i in 1 ..< degree[u]:
      let key = neighbors[u * MaxN + i]
      var j = i
      while j > 0 and angleLess(key, neighbors[u * MaxN + j - 1], u, points):
        neighbors[u * MaxN + j] = neighbors[u * MaxN + j - 1]
        dec j
      neighbors[u * MaxN + j] = key

  var used = default(array[MaxN * MaxN, bool])
  var faces = 0'i64
  for e in 0 ..< m:
    for direction in 0 ..< 2:
      var u = if direction == 0: edgeU[e] else: edgeV[e]
      var v = if direction == 0: edgeV[e] else: edgeU[e]
      if used[u * MaxN + v]: continue
      inc faces
      var steps = 0
      while not used[u * MaxN + v]:
        used[u * MaxN + v] = true
        var reverse = -1
        for i in 0 ..< degree[v]:
          if neighbors[v * MaxN + i] == u: reverse = i
        if reverse < 0 or degree[v] == 0: return -1
        let next = neighbors[v * MaxN + (reverse + 1) mod degree[v]]
        u = v
        v = next
        inc steps
        if steps > 2 * m: return -1
  faces
