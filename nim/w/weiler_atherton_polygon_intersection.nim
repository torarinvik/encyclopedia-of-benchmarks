import std/ffi

const MaxV = 6
const MaxX = MaxV * MaxV
const MaxNode = MaxV + MaxX
const MaxWords = 210

type
  Rat = object
    n, d: int64
  Point = object
    xn, xd, yn, yd: int64
  Crossing = object
    p: Point
    ta, tb: Rat
    ae, ax, be, bx: bool
  Node = object
    p: Point
    cross: int
  Ring = object
    p: array[48, Point]
    count: int

proc abs64(x: int64): int64 =
  if x < 0: -x else: x

proc gcd64(a0, b0: int64): int64 =
  var a = abs64(a0)
  var b = abs64(b0)
  while b != 0:
    let r = a mod b
    a = b
    b = r
  if a == 0: 1 else: a

proc makeRat(n0, d0: int64): Rat =
  var n = n0
  var d = d0
  if d < 0:
    n = -n
    d = -d
  let g = gcd64(n, d)
  Rat(n: n div g, d: d div g)

proc lessRat(a, b: Rat): bool = a.n * b.d < b.n * a.d
proc equalPoint(a, b: Point): bool =
  a.xn == b.xn and a.xd == b.xd and a.yn == b.yn and a.yd == b.yd
proc lessPoint(a, b: Point): bool =
  let ax = a.xn * b.xd
  let bx = b.xn * a.xd
  if ax != bx: return ax < bx
  a.yn * b.yd < b.yn * a.yd
proc intPoint(x, y: int64): Point = Point(xn: x, xd: 1, yn: y, yd: 1)

proc orient(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

proc onSegment(ax, ay, bx, by, px, py: int64): bool =
  orient(ax, ay, bx, by, px, py) == 0 and
    px >= min(ax, bx) and px <= max(ax, bx) and
    py >= min(ay, by) and py <= max(ay, by)

proc segmentRelation(ax, ay, bx, by, cx, cy, dx, dy: int64): int =
  let o1 = orient(ax, ay, bx, by, cx, cy)
  let o2 = orient(ax, ay, bx, by, dx, dy)
  let o3 = orient(cx, cy, dx, dy, ax, ay)
  let o4 = orient(cx, cy, dx, dy, bx, by)
  if ((o1 > 0 and o2 < 0) or (o1 < 0 and o2 > 0)) and
     ((o3 > 0 and o4 < 0) or (o3 < 0 and o4 > 0)):
    return 1
  if (o1 == 0 and onSegment(ax, ay, bx, by, cx, cy)) or
     (o2 == 0 and onSegment(ax, ay, bx, by, dx, dy)) or
     (o3 == 0 and onSegment(cx, cy, dx, dy, ax, ay)) or
     (o4 == 0 and onSegment(cx, cy, dx, dy, bx, by)):
    return 2
  0

proc polygonValid(poly: array[12, int64], n: int): bool =
  var area = 0'i64
  for i in 0 ..< n:
    let prev = (i + n - 1) mod n
    let next = (i + 1) mod n
    let x = poly[2 * i]
    let y = poly[2 * i + 1]
    let nx = poly[2 * next]
    let ny = poly[2 * next + 1]
    area += x * ny - y * nx
    if orient(poly[2 * prev], poly[2 * prev + 1], x, y, nx, ny) == 0: return false
    for j in 0 ..< i:
      if x == poly[2 * j] and y == poly[2 * j + 1]: return false
  if area <= 0: return false
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if j == i + 1 or (i == 0 and j == n - 1): continue
      let k = (i + 1) mod n
      let l = (j + 1) mod n
      if segmentRelation(poly[2 * i], poly[2 * i + 1], poly[2 * k], poly[2 * k + 1],
                         poly[2 * j], poly[2 * j + 1], poly[2 * l], poly[2 * l + 1]) != 0:
        return false
  true

proc inside(x, y: int64, poly: array[12, int64], n: int): bool =
  var winding = 0
  for i in 0 ..< n:
    let j = (i + 1) mod n
    let side = orient(poly[2 * i], poly[2 * i + 1], poly[2 * j], poly[2 * j + 1], x, y)
    if poly[2 * i + 1] <= y and y < poly[2 * j + 1] and side > 0: inc winding
    elif poly[2 * j + 1] <= y and y < poly[2 * i + 1] and side < 0: dec winding
  winding != 0

proc intersection(ax, ay, bx, by, cx, cy, dx, dy: int64,
                  ta, tb: var Rat): Point =
  let rx = bx - ax
  let ry = by - ay
  let sx = dx - cx
  let sy = dy - cy
  var den = rx * sy - ry * sx
  var tn = (cx - ax) * sy - (cy - ay) * sx
  var un = (cx - ax) * ry - (cy - ay) * rx
  if den < 0:
    den = -den
    tn = -tn
    un = -un
  ta = makeRat(tn, den)
  tb = makeRat(un, den)
  let xr = makeRat(ax * den + rx * tn, den)
  let yr = makeRat(ay * den + ry * tn, den)
  Point(xn: xr.n, xd: xr.d, yn: yr.n, yd: yr.d)

proc canonicalize(rings: var array[16, Ring], ringCount: int) =
  for r in 0 ..< ringCount:
    var pivot = 0
    for i in 1 ..< rings[r].count:
      if lessPoint(rings[r].p[i], rings[r].p[pivot]): pivot = i
    if pivot != 0:
      var temp: array[48, Point]
      for i in 0 ..< rings[r].count: temp[i] = rings[r].p[(pivot + i) mod rings[r].count]
      for i in 0 ..< rings[r].count: rings[r].p[i] = temp[i]
  for i in 1 ..< ringCount:
    let key = rings[i]
    var j = i - 1
    while j >= 0 and lessPoint(key.p[0], rings[j].p[0]):
      rings[j + 1] = rings[j]
      dec j
    rings[j + 1] = key

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc weiler_atherton_polygon_intersection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "weiler_atherton_polygon_intersection".} =
  if input == nil or length < 2 or length > 27: return -1
  let naWord = input[0]
  let nbWord = input[1]
  if naWord < 3 or naWord > MaxV or nbWord < 3 or nbWord > MaxV or
     int(length) != 2 + 2 * int(naWord) + 2 * int(nbWord): return -1
  let na = int(naWord)
  let nb = int(nbWord)
  var a: array[12, int64]
  var b: array[12, int64]
  var cursor = 2
  for i in 0 ..< 2 * na:
    let value = input[cursor]
    inc cursor
    if value < -16 or value > 16: return -1
    a[i] = value
  for i in 0 ..< 2 * nb:
    let value = input[cursor]
    inc cursor
    if value < -16 or value > 16: return -1
    b[i] = value
  if not polygonValid(a, na) or not polygonValid(b, nb): return -1

  var crossings: array[MaxX, Crossing]
  var eventsA: array[MaxV, array[MaxV, int]]
  var eventsB: array[MaxV, array[MaxV, int]]
  var countA: array[MaxV, int]
  var countB: array[MaxV, int]
  var crossingCount = 0
  for i in 0 ..< na:
    for j in 0 ..< nb:
      let ai = (i + 1) mod na
      let bj = (j + 1) mod nb
      let rel = segmentRelation(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],
                               b[2*j],b[2*j+1],b[2*bj],b[2*bj+1])
      if rel == 2: return -1
      if rel == 1:
        var c = Crossing()
        c.p = intersection(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],
                            b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],c.ta,c.tb)
        let ab = orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*i],a[2*i+1])
        let aa = orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*ai],a[2*ai+1])
        let bb = orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1])
        let ba = orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*bj],b[2*bj+1])
        c.ae = ab < 0 and aa > 0; c.ax = ab > 0 and aa < 0
        c.be = bb < 0 and ba > 0; c.bx = bb > 0 and ba < 0
        if (not c.ae and not c.ax) or (not c.be and not c.bx) or c.ae == c.be: return -1
        crossings[crossingCount] = c
        eventsA[i][countA[i]] = crossingCount
        eventsB[j][countB[j]] = crossingCount
        inc countA[i]; inc countB[j]; inc crossingCount

  var rings: array[16, Ring]
  var ringCount = 0
  if crossingCount == 0:
    if inside(a[0],a[1],b,nb):
      rings[0].count = na
      for i in 0 ..< na: rings[0].p[i] = intPoint(a[2*i],a[2*i+1])
      ringCount = 1
    elif inside(b[0],b[1],a,na):
      rings[0].count = nb
      for i in 0 ..< nb: rings[0].p[i] = intPoint(b[2*i],b[2*i+1])
      ringCount = 1
  else:
    var nodesA: array[MaxNode, Node]
    var nodesB: array[MaxNode, Node]
    var nodeCountA = 0
    var nodeCountB = 0
    var posA: array[MaxX, int]
    var posB: array[MaxX, int]
    for edge in 0 ..< na:
      nodesA[nodeCountA] = Node(p: intPoint(a[2*edge],a[2*edge+1]), cross: -1)
      inc nodeCountA
      for k in 1 ..< countA[edge]:
        let id = eventsA[edge][k]
        var j = k - 1
        while j >= 0 and lessRat(crossings[id].ta, crossings[eventsA[edge][j]].ta):
          eventsA[edge][j+1] = eventsA[edge][j]
          dec j
        eventsA[edge][j+1] = id
      for k in 0 ..< countA[edge]:
        let id = eventsA[edge][k]
        nodesA[nodeCountA] = Node(p: crossings[id].p, cross: id)
        posA[id] = nodeCountA
        inc nodeCountA
    for edge in 0 ..< nb:
      nodesB[nodeCountB] = Node(p: intPoint(b[2*edge],b[2*edge+1]), cross: -1)
      inc nodeCountB
      for k in 1 ..< countB[edge]:
        let id = eventsB[edge][k]
        var j = k - 1
        while j >= 0 and lessRat(crossings[id].tb, crossings[eventsB[edge][j]].tb):
          eventsB[edge][j+1] = eventsB[edge][j]
          dec j
        eventsB[edge][j+1] = id
      for k in 0 ..< countB[edge]:
        let id = eventsB[edge][k]
        nodesB[nodeCountB] = Node(p: crossings[id].p, cross: id)
        posB[id] = nodeCountB
        inc nodeCountB
    var visited: array[MaxX, bool]
    for start in 0 ..< nodeCountA:
      let sid = nodesA[start].cross
      if sid < 0 or not crossings[sid].ae or visited[sid]: continue
      if ringCount >= 16: return -1
      var ring = Ring()
      ring.p[0] = nodesA[start].p; ring.count = 1; visited[sid] = true
      var activeA = true
      var index = start
      var guard = 0
      while true:
        inc guard
        if guard > 2 * crossingCount + na + nb + 1: return -1
        let nodeCount = if activeA: nodeCountA else: nodeCountB
        let next = (index + 1) mod nodeCount
        let node = if activeA: nodesA[next] else: nodesB[next]
        if node.cross >= 0:
          let id = node.cross
          visited[id] = true
          if activeA and id == sid: break
          let exits = if activeA: crossings[id].ax else: crossings[id].bx
          if exits:
            if id == sid: break
            activeA = not activeA
            index = if activeA: posA[id] else: posB[id]
            continue
        if ring.count >= 48: return -1
        ring.p[ring.count] = node.p; inc ring.count
        index = next
      if ring.count < 3: return -1
      rings[ringCount] = ring; inc ringCount
    for id in 0 ..< crossingCount:
      if not visited[id]: return -1

  canonicalize(rings, ringCount)
  var staged: array[MaxWords, int64]
  var words = 0
  staged[words] = int64(ringCount); inc words
  for r in 0 ..< ringCount:
    staged[words] = int64(rings[r].count); inc words
    for i in 0 ..< rings[r].count:
      let p = rings[r].p[i]
      staged[words] = p.xn; staged[words+1] = p.xd
      staged[words+2] = p.yn; staged[words+3] = p.yd
      words += 4
  let outputBytes = words * 8
  if outputBytes > 1680: return -1
  if output == nil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< words: storeLe(output, i * 8, staged[i])
  int64(outputBytes)
