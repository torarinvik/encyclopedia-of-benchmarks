import std/algorithm

type
  InputPtr = ptr UncheckedArray[int64]
  Point = object
    x, y: int64
  AngleRef = object
    a, b, c, vertex: int
  Triangle = object
    a, b, c: int

const
  MinN = 3
  MaxN = 4
  MaxLength = 10
  MaxAngles = 12

proc orient(p: array[MaxN, Point], a, b, c: int): int64 =
  (p[b].x - p[a].x) * (p[c].y - p[a].y) - (p[b].y - p[a].y) * (p[c].x - p[a].x)

proc angleParts(p: array[MaxN, Point], angle: AngleRef): tuple[dot, den: int64] =
  let vertices = [angle.a, angle.b, angle.c]
  let center = vertices[angle.vertex]
  var endpoints: array[2, int]
  var used = 0
  for vertex in vertices:
    if vertex != center:
      endpoints[used] = vertex
      inc used
  let ux = p[endpoints[0]].x - p[center].x
  let uy = p[endpoints[0]].y - p[center].y
  let vx = p[endpoints[1]].x - p[center].x
  let vy = p[endpoints[1]].y - p[center].y
  (ux * vx + uy * vy, (ux * ux + uy * uy) * (vx * vx + vy * vy))

proc angleCmp(p: array[MaxN, Point], left, right: AngleRef): int =
  let l = angleParts(p, left)
  let r = angleParts(p, right)
  if l.dot == 0 or r.dot == 0:
    if l.dot == r.dot: return 0
    if l.dot == 0: return (if r.dot > 0: 1 else: -1)
    return (if l.dot > 0: -1 else: 1)
  if (l.dot < 0) != (r.dot < 0): return (if l.dot < 0: 1 else: -1)
  let lhs = l.dot * l.dot * r.den
  let rhs = r.dot * r.dot * l.den
  if lhs == rhs: return 0
  if l.dot > 0: return (if lhs > rhs: -1 else: 1)
  (if lhs > rhs: 1 else: -1)

proc triangleMax(p: array[MaxN, Point], t: Triangle): AngleRef =
  var vertices = [t.a, t.b, t.c]
  vertices.sort()
  result = AngleRef(a: vertices[0], b: vertices[1], c: vertices[2], vertex: 0)
  for position in 1 .. 2:
    let candidate = AngleRef(a: vertices[0], b: vertices[1], c: vertices[2], vertex: position)
    if angleCmp(p, candidate, result) > 0: result = candidate

proc triangulationMax(p: array[MaxN, Point], triangles: openArray[Triangle]): AngleRef =
  result = triangleMax(p, triangles[0])
  for i in 1 ..< triangles.len:
    let candidate = triangleMax(p, triangles[i])
    if angleCmp(p, candidate, result) > 0: result = candidate

proc angleRank(p: array[MaxN, Point], n: int, target: AngleRef): int64 =
  var distinctLower: array[MaxAngles, AngleRef]
  var distinctCount = 0
  for a in 0 ..< n:
    for b in a + 1 ..< n:
      for c in b + 1 ..< n:
        for vertex in 0 .. 2:
          let candidate = AngleRef(a: a, b: b, c: c, vertex: vertex)
          if angleCmp(p, candidate, target) >= 0: continue
          var seen = false
          for i in 0 ..< distinctCount:
            if angleCmp(p, candidate, distinctLower[i]) == 0: seen = true
          if not seen:
            distinctLower[distinctCount] = candidate
            inc distinctCount
  int64(distinctCount + 1)

proc properCrossing(p: array[MaxN, Point], a, b, c, d: int): bool =
  orient(p, a, b, c) * orient(p, a, b, d) < 0 and
    orient(p, c, d, a) * orient(p, c, d, b) < 0

proc convex_polygon_minimax_angle_edge_insertion*(input: InputPtr, length: csize_t): int64
    {.cdecl, exportc: "convex_polygon_minimax_angle_edge_insertion".} =
  if input == nil or length < 1 or length > csize_t(MaxLength): return -1
  if input[0] < MinN.int64 or input[0] > MaxN.int64: return -1
  let n = int(input[0])
  if int(length) != 1 + 2 * n: return -1
  var p: array[MaxN, Point]
  for i in 0 ..< n:
    p[i] = Point(x: input[1 + 2 * i], y: input[2 + 2 * i])
    if p[i].x < -16 or p[i].x > 16 or p[i].y < -16 or p[i].y > 16: return -1
    for j in 0 ..< i:
      if p[i].x == p[j].x and p[i].y == p[j].y: return -1
  var area2 = 0'i64
  for i in 0 ..< n:
    let next = (i + 1) mod n
    area2 += p[i].x * p[next].y - p[i].y * p[next].x
  if area2 == 0: return -1
  let orientation = (if area2 > 0: 1'i64 else: -1'i64)
  for a in 0 ..< n:
    for b in a + 1 ..< n:
      for c in b + 1 ..< n:
        if orient(p, a, b, c) == 0: return -1
  for edge in 0 ..< n:
    let next = (edge + 1) mod n
    for vertex in 0 ..< n:
      if vertex != edge and vertex != next and orientation * orient(p, edge, next, vertex) <= 0: return -1

  var worst: AngleRef
  let fan = [Triangle(a: 0, b: 1, c: 2), Triangle(a: 0, b: 2, c: 3)]
  if n == 3:
    worst = triangleMax(p, Triangle(a: 0, b: 1, c: 2))
  else:
    worst = triangulationMax(p, fan)
  if n == 4:
    var accepted = false
    for triangle in fan:
      if accepted: break
      let vertices = [triangle.a, triangle.b, triangle.c]
      for vertex in 0 .. 2:
        if accepted: break
        let candidate = AngleRef(a: vertices[0], b: vertices[1], c: vertices[2], vertex: vertex)
        if angleCmp(p, candidate, worst) != 0: continue
        let q = vertices[vertex]
        var opposite: array[2, int]
        var used = 0
        var s = -1
        for i in 0 .. 2:
          if i != vertex:
            opposite[used] = vertices[i]
            inc used
        for point in 0 ..< 4:
          if point != vertices[0] and point != vertices[1] and point != vertices[2]: s = point
        if not properCrossing(p, q, s, opposite[0], opposite[1]): continue
        let inserted = [Triangle(a: q, b: s, c: opposite[0]), Triangle(a: q, b: s, c: opposite[1])]
        let replacement = triangulationMax(p, inserted)
        if angleCmp(p, replacement, worst) < 0:
          worst = replacement
          accepted = true
  angleRank(p, n, worst)
