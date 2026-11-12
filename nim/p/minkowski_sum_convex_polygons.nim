const MaxVertices = 32
const MaxInput = 131
const MaxCoord = 1_000_000'i64

type Point = object
  x, y: int64

proc cross(a, b: Point): int64 = a.x * b.y - a.y * b.x
proc edge(p: ptr UncheckedArray[Point], n, i: int): Point =
  let next = p[(i + 1) mod n]
  Point(x: next.x - p[i].x, y: next.y - p[i].y)
proc half(v: Point): int =
  if v.y > 0 or (v.y == 0 and v.x >= 0): 0 else: 1
proc angleCompare(a, b: Point): int =
  let ha = half(a)
  let hb = half(b)
  if ha != hb: return cmp(ha, hb)
  let turn = cross(a, b)
  if turn > 0: -1 elif turn < 0: 1 else: 0
proc validPolygon(p: ptr UncheckedArray[Point], n: int): bool =
  var wraps = 0
  for i in 0 ..< n:
    let a = edge(p, n, i)
    let b = edge(p, n, (i + 1) mod n)
    if (a.x == 0 and a.y == 0) or cross(a, b) <= 0: return false
    if angleCompare(b, a) < 0: inc wraps
  wraps == 1
proc rotateLowest(p: ptr UncheckedArray[Point], n: int) =
  var first = 0
  for i in 1 ..< n:
    if p[i].y < p[first].y or (p[i].y == p[first].y and p[i].x < p[first].x): first = i
  var tmp: array[MaxVertices, Point]
  for i in 0 ..< n: tmp[i] = p[(first + i) mod n]
  for i in 0 ..< n: p[i] = tmp[i]
proc putI64(outBytes: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    outBytes[offset] = uint8((bits shr (8 * b)) and 255)
    inc offset

proc minkowski_sum_convex_polygons*(values: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minkowski_sum_convex_polygons".} =
  if values.isNil or n < 14 or n > csize_t(MaxInput): return -1
  if values[0] < 3 or values[0] > int64(MaxVertices) or values[1] < 3 or values[1] > int64(MaxVertices): return -1
  let pn = int(values[0])
  let qn = int(values[1])
  if int(n) != 2 + 2 * pn + 2 * qn: return -1
  var p: array[MaxVertices, Point]
  var q: array[MaxVertices, Point]
  var sums: array[2 * MaxVertices, Point]
  var at = 2
  for i in 0 ..< pn:
    p[i] = Point(x: values[at], y: values[at + 1]); at += 2
    if p[i].x < -MaxCoord or p[i].x > MaxCoord or p[i].y < -MaxCoord or p[i].y > MaxCoord: return -1
  for i in 0 ..< qn:
    q[i] = Point(x: values[at], y: values[at + 1]); at += 2
    if q[i].x < -MaxCoord or q[i].x > MaxCoord or q[i].y < -MaxCoord or q[i].y > MaxCoord: return -1
  if not validPolygon(cast[ptr UncheckedArray[Point]](addr p[0]), pn) or
      not validPolygon(cast[ptr UncheckedArray[Point]](addr q[0]), qn): return -1
  rotateLowest(cast[ptr UncheckedArray[Point]](addr p[0]), pn)
  rotateLowest(cast[ptr UncheckedArray[Point]](addr q[0]), qn)
  var i = 0
  var j = 0
  var count = 0
  let pp = cast[ptr UncheckedArray[Point]](addr p[0])
  let qq = cast[ptr UncheckedArray[Point]](addr q[0])
  while i < pn or j < qn:
    sums[count] = Point(x: pp[i mod pn].x + qq[j mod qn].x,
      y: pp[i mod pn].y + qq[j mod qn].y)
    inc count
    if i == pn: inc j; continue
    if j == qn: inc i; continue
    let order = angleCompare(edge(pp, pn, i), edge(qq, qn, j))
    if order <= 0: inc i
    if order >= 0: inc j
  let needed = (1 + 2 * count) * 8
  if csize_t(needed) > capacity or output.isNil: return -2
  var offset = 0
  putI64(output, offset, int64(count))
  for k in 0 ..< count:
    putI64(output, offset, sums[k].x)
    putI64(output, offset, sums[k].y)
  int64(needed)
