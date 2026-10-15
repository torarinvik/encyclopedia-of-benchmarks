const MaxVertices = 64

type
  Point = object
    x, y: int64
  PointArray = array[MaxVertices, Point]
  BoolArray = array[MaxVertices, bool]

proc orient(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc onSegment(a, b, p: Point): bool =
  orient(a, b, p) == 0 and p.x >= min(a.x, b.x) and p.x <= max(a.x, b.x) and
    p.y >= min(a.y, b.y) and p.y <= max(a.y, b.y)

proc segmentsIntersect(a, b, c, d: Point): bool =
  let abC = orient(a, b, c)
  let abD = orient(a, b, d)
  let cdA = orient(c, d, a)
  let cdB = orient(c, d, b)
  if abC == 0 and onSegment(a, b, c): return true
  if abD == 0 and onSegment(a, b, d): return true
  if cdA == 0 and onSegment(c, d, a): return true
  if cdB == 0 and onSegment(c, d, b): return true
  (abC < 0) != (abD < 0) and (cdA < 0) != (cdB < 0)

proc inOrOnTriangle(a, b, c, p: Point, winding: int64): bool =
  orient(a, b, p) * winding >= 0 and orient(b, c, p) * winding >= 0 and
    orient(c, a, p) * winding >= 0

proc writeTriangle(output: ptr UncheckedArray[uint8], position, a, b, c: int) =
  for slot, index in [a, b, c]:
    let value = uint32(index)
    for byte in 0 ..< 4:
      output[position * 12 + slot * 4 + byte] = uint8((value shr (8 * byte)) and 0xFF'u32)

proc ear_clipping_polygon_triangulation*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "ear_clipping_polygon_triangulation".} =
  if length < 6 or length > 2 * MaxVertices or length mod 2 != 0 or values == nil: return -1
  let n = int(length div 2)
  var points: PointArray
  for i in 0 ..< n:
    let x = values[2 * i]
    let y = values[2 * i + 1]
    if x < -10_000 or x > 10_000 or y < -10_000 or y > 10_000: return -1
    points[i] = Point(x: x, y: y)
    for prior in 0 ..< i:
      if points[prior].x == x and points[prior].y == y: return -1

  var twiceArea = 0'i64
  for i in 0 ..< n:
    let next = (i + 1) mod n
    let after = (i + 2) mod n
    if orient(points[i], points[next], points[after]) == 0: return -1
    twiceArea += points[i].x * points[next].y - points[i].y * points[next].x
  if twiceArea == 0: return -1
  for i in 0 ..< n:
    let iNext = (i + 1) mod n
    for j in (i + 1) ..< n:
      let jNext = (j + 1) mod n
      if iNext == j or jNext == i: continue
      if segmentsIntersect(points[i], points[iNext], points[j], points[jNext]): return -1

  let required = 12 * (n - 2)
  if output == nil or outputCapacity < csize_t(required): return -2
  let winding = if twiceArea > 0: 1'i64 else: -1'i64
  var live: BoolArray
  for i in 0 ..< n: live[i] = true
  var remaining = n
  var emitted = 0
  while remaining > 3:
    var found = false
    for current in 0 ..< n:
      if not live[current]: continue
      var previous = (current + n - 1) mod n
      while not live[previous]: previous = (previous + n - 1) mod n
      var next = (current + 1) mod n
      while not live[next]: next = (next + 1) mod n
      if orient(points[previous], points[current], points[next]) * winding <= 0: continue
      var blocked = false
      for candidate in 0 ..< n:
        if live[candidate] and candidate != previous and candidate != current and candidate != next and
            inOrOnTriangle(points[previous], points[current], points[next], points[candidate], winding):
          blocked = true
          break
      if blocked: continue
      writeTriangle(output, emitted, previous, current, next)
      inc emitted
      live[current] = false
      dec remaining
      found = true
      break
    if not found: return -1

  var finalIds: array[3, int]
  var finalCount = 0
  for i in 0 ..< n:
    if live[i]:
      finalIds[finalCount] = i
      inc finalCount
  if finalCount != 3: return -1
  writeTriangle(output, emitted, finalIds[0], finalIds[1], finalIds[2])
  int64(n - 2)
