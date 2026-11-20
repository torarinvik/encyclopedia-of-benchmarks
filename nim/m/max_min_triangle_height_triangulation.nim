const
  MinN = 3
  MaxN = 5
  MaxLength = 12
  DpSize = 10

type
  Point = object
    x, y: int64
  Score = object
    num, den: int64
  Cell = object
    minimum: Score
    count: int
    valid: bool
    split: int
  Triangle = object
    a, b, c: int
  Triangles = object
    items: array[3, Triangle]
    count: int
  Objective = object
    minimum: Score
    count: int

proc orient(a, b, c: Point): int64 =
  (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)

proc gcd64(a0, b0: int64): int64 =
  var a = a0
  var b = b0
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a

proc fraction(num, den: int64): Score =
  let divisor = gcd64(num, den)
  Score(num: num div divisor, den: den div divisor)

proc compare(a, b: Score): int =
  let left = a.num * b.den
  let right = b.num * a.den
  if left < right: -1
  elif left > right: 1
  else: 0

proc triangleScore(points: array[MaxN, Point], n, a, b, c: int): Score =
  let p = points[a mod n]
  let q = points[b mod n]
  let r = points[c mod n]
  let area = abs(orient(p, q, r))
  let lengths = [
    (p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y),
    (q.x-r.x)*(q.x-r.x)+(q.y-r.y)*(q.y-r.y),
    (r.x-p.x)*(r.x-p.x)+(r.y-p.y)*(r.y-p.y)]
  var best = fraction(area*area, lengths[0])
  for i in 1 ..< 3:
    let candidate = fraction(area*area, lengths[i])
    if compare(candidate, best) < 0: best = candidate
  best

proc join(left, right: Cell, triangle: Score): Objective =
  var result = Objective(minimum: triangle, count: 1)
  for child in [left, right]:
    if not child.valid: continue
    let cmp = compare(child.minimum, result.minimum)
    if cmp < 0:
      result.minimum = child.minimum
      result.count = child.count
    elif cmp == 0:
      result.count += child.count
  result

proc better(candidate, current: Objective): bool =
  let cmp = compare(candidate.minimum, current.minimum)
  cmp > 0 or (cmp == 0 and candidate.count < current.count)

proc evaluate(points: array[MaxN, Point], n: int, triangles: Triangles): Objective =
  let first = triangles.items[0]
  var result = Objective(minimum: triangleScore(points, n, first.a, first.b, first.c), count: 1)
  for i in 1 ..< triangles.count:
    let t = triangles.items[i]
    let score = triangleScore(points, n, t.a, t.b, t.c)
    let cmp = compare(score, result.minimum)
    if cmp < 0:
      result.minimum = score
      result.count = 1
    elif cmp == 0:
      inc result.count
  result

proc collect(start, finish: int, table: array[DpSize*DpSize, Cell], n: int,
             output: var Triangles) =
  if finish - start < 2: return
  let middle = table[start*DpSize + finish].split
  output.items[output.count] = Triangle(a: start mod n, b: middle mod n, c: finish mod n)
  inc output.count
  collect(start, middle, table, n, output)
  collect(middle, finish, table, n, output)

proc hasEdge(triangles: Triangles, left, right: int): bool =
  for i in 0 ..< triangles.count:
    let t = triangles.items[i]
    for pair in [(t.a, t.b), (t.b, t.c), (t.c, t.a)]:
      if min(pair[0], pair[1]) == left and max(pair[0], pair[1]) == right:
        return true
  false

proc solve(points: array[MaxN, Point], n: int): int64 =
  var table: array[DpSize*DpSize, Cell]
  if n > 3:
    for span in 2 .. n-2:
      for start in 0 ..< n:
        let finish = start + span
        var best: Objective
        var bestMiddle = -1
        for middle in start+1 ..< finish:
          let candidate = join(table[start*DpSize+middle], table[middle*DpSize+finish],
                               triangleScore(points, n, start, middle, finish))
          if bestMiddle < 0 or better(candidate, best):
            best = candidate
            bestMiddle = middle
        table[start*DpSize+finish] = Cell(minimum: best.minimum, count: best.count,
                                           valid: true, split: bestMiddle)
  var current: Triangles
  for middle in 1 ..< n-1:
    current.items[current.count] = Triangle(a: 0, b: middle, c: middle+1)
    inc current.count
  var currentValue = evaluate(points, n, current)
  var improvements = 0
  while true:
    var changed = false
    for left in 0 ..< n:
      if changed: break
      for right in left+2 ..< n:
        if left == 0 and right == n-1: continue
        if hasEdge(current, left, right): continue
        var candidate: Triangles
        collect(left, right, table, n, candidate)
        collect(right, left+n, table, n, candidate)
        let value = evaluate(points, n, candidate)
        if better(value, currentValue):
          current = candidate
          currentValue = value
          inc improvements
          if improvements > 30: return -1
          changed = true
          break
    if not changed: return currentValue.minimum.num*513 + currentValue.minimum.den

proc max_min_triangle_height_triangulation*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "max_min_triangle_height_triangulation".} =
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
    let next = (i+1) mod n
    area2 += points[i].x*points[next].y - points[i].y*points[next].x
  if area2 <= 0: return -1
  for a in 0 ..< n:
    for b in a+1 ..< n:
      for c in b+1 ..< n:
        if orient(points[a], points[b], points[c]) == 0: return -1
  for edge in 0 ..< n:
    let next = (edge+1) mod n
    for vertex in 0 ..< n:
      if vertex != edge and vertex != next and orient(points[edge], points[next], points[vertex]) <= 0:
        return -1
  solve(points, n)
