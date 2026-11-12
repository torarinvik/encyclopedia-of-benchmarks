type
  Point = tuple[x, y: int64]
  I64Input = ptr UncheckedArray[int64]

const
  MaxPoints = 64
  CoordLimit = 1_000_000'i64

proc cross(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc before(a, b: Point): bool = a.x < b.x or (a.x == b.x and a.y < b.y)

proc convex_layers*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "convex_layers".} =
  if input == nil or length < 1 or length > csize_t(1 + 2 * MaxPoints): return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > MaxPoints.int64: return -1
  let inputCount = int(rawCount)
  if length != csize_t(1 + 2 * inputCount): return -1

  var points = newSeq[Point]()
  for index in 0 ..< inputCount:
    let point: Point = (x: input[1 + 2 * index], y: input[2 + 2 * index])
    if point.x < -CoordLimit or point.x > CoordLimit or point.y < -CoordLimit or point.y > CoordLimit:
      return -1
    var duplicate = false
    for old in points:
      if old == point: duplicate = true
    if not duplicate: points.add(point)

  var layers = 0'i64
  while points.len > 0:
    for index in 1 ..< points.len:
      let key = points[index]
      var position = index
      while position > 0 and before(key, points[position - 1]):
        points[position] = points[position - 1]
        dec position
      points[position] = key

    var hull = newSeq[Point]()
    for point in points:
      while hull.len >= 2 and cross(hull[hull.len - 2], hull[^1], point) <= 0:
        hull.setLen(hull.len - 1)
      hull.add(point)
    let lower = hull.len
    if points.len > 1:
      for index in countdown(points.len - 2, 0):
        let point = points[index]
        while hull.len > lower and cross(hull[hull.len - 2], hull[^1], point) <= 0:
          hull.setLen(hull.len - 1)
        hull.add(point)
    if hull.len > 1: hull.setLen(hull.len - 1)

    var boundary = newSeq[bool](points.len)
    if hull.len <= 2:
      for index in 0 ..< points.len: boundary[index] = true
    else:
      for index, point in points.pairs:
        for edge in 0 ..< hull.len:
          let a = hull[edge]
          let b = hull[(edge + 1) mod hull.len]
          if cross(a, b, point) == 0 and min(a.x, b.x) <= point.x and point.x <= max(a.x, b.x) and
              min(a.y, b.y) <= point.y and point.y <= max(a.y, b.y):
            boundary[index] = true
            break
    var remaining = newSeq[Point]()
    for index, point in points.pairs:
      if not boundary[index]: remaining.add(point)
    if remaining.len == points.len: return -1
    points = remaining
    inc layers
  layers
