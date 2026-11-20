const
  MinN = 3
  MaxN = 6
  MaxLength = 14

type Point = object
  x, y: int64

proc orient(a, b, c: Point): int64 =
  (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)

proc distanceSquared(a, b: Point): int64 =
  let dx = a.x-b.x
  let dy = a.y-b.y
  dx*dx+dy*dy

proc diagonalBit(n, a0, b0: int): int =
  let left = min(a0, b0)
  let right = max(a0, b0)
  var bit = 0
  for first in 0 ..< n:
    for second in first+2 ..< n:
      if first == 0 and second == n-1: continue
      if first == left and second == right: return bit
      inc bit
  -1

proc angleAtLeastSixty(p, q, r: Point): bool =
  let ux = p.x-q.x
  let uy = p.y-q.y
  let vx = r.x-q.x
  let vy = r.y-q.y
  let dot = ux*vx+uy*vy
  if dot <= 0: return true
  let normU = ux*ux+uy*uy
  let normV = vx*vx+vy*vy
  4*dot*dot <= normU*normV

proc greedy(points: array[MaxN, Point], n: int): int64 =
  var next: array[MaxN, int]
  for i in 0 ..< n: next[i] = (i+1) mod n
  var shortest = 513'i64
  for i in 0 ..< n:
    shortest = min(shortest, distanceSquared(points[i], points[(i+1) mod n]))
  var active = n
  var p = 0
  var q = next[p]
  var r = next[q]
  var steps = 0
  var diagonalMask = 0'i64
  while active > 3:
    inc steps
    if steps > 4*n: return -1
    if angleAtLeastSixty(points[p], points[q], points[r]):
      shortest = min(shortest, distanceSquared(points[p], points[r]))
      let bit = diagonalBit(n, p, r)
      if bit < 0: return -1
      diagonalMask += 1'i64 shl bit
      next[p] = r
      dec active
      q = r
      r = next[r]
    else:
      p = q
      q = r
      r = next[r]
  shortest*512+diagonalMask

proc convex_polygon_max_min_length_triangulation*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "convex_polygon_max_min_length_triangulation".} =
  if input == nil or length < 1 or length > csize_t(MaxLength): return -1
  let nValue = input[0]
  if nValue < MinN or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2*n: return -1
  var points: array[MaxN, Point]
  for i in 0 ..< n:
    points[i] = Point(x: input[1+2*i], y: input[2+2*i])
    if points[i].x < -8 or points[i].x > 8 or points[i].y < -8 or points[i].y > 8: return -1
    for j in 0 ..< i:
      if points[i].x == points[j].x and points[i].y == points[j].y: return -1
  var area2 = 0'i64
  for i in 0 ..< n:
    let following = (i+1) mod n
    area2 += points[i].x*points[following].y-points[i].y*points[following].x
  if area2 <= 0: return -1
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        if orient(points[a], points[b], points[c]) == 0: return -1
  for edge in 0 ..< n:
    let following = (edge+1) mod n
    for vertex in 0 ..< n:
      if vertex != edge and vertex != following and orient(points[edge], points[following], points[vertex]) <= 0:
        return -1
  greedy(points, n)
