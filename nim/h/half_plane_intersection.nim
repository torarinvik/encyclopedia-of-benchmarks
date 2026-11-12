const MaxLines = 16
const MaxInput = 37
const BoxLimit = 256'i64

type
  Halfplane = object
    a, b, c: int64
  Point = object
    x, y, den: int64

proc abs64(x: int64): int64 =
  if x < 0: -x else: x
proc gcd64(a0, b0: int64): int64 =
  var a = abs64(a0)
  var b = abs64(b0)
  while b != 0:
    let r = a mod b
    a = b
    b = r
  a
proc angleHalf(h: Halfplane): int =
  if h.b > 0 or (h.b == 0 and h.a >= 0): 0 else: 1
proc lineCompare(x, y: Halfplane): int =
  let hx = angleHalf(x)
  let hy = angleHalf(y)
  if hx != hy: return cmp(hx, hy)
  let turn = x.a * y.b - x.b * y.a
  if turn != 0: return (if turn > 0: -1 else: 1)
  cmp(x.c, y.c)
proc intersect(x, y: Halfplane, p: var Point): bool =
  var det = x.a * y.b - y.a * x.b
  if det == 0: return false
  var xn = x.c * y.b - x.b * y.c
  var yn = x.a * y.c - x.c * y.a
  if det < 0:
    det = -det
    xn = -xn
    yn = -yn
  let g = gcd64(gcd64(xn, yn), det)
  p = Point(x: xn div g, y: yn div g, den: det div g)
  true
proc outside(h: Halfplane, p: Point): bool = h.a * p.x + h.b * p.y > h.c * p.den
proc samePoint(x, y: Point): bool = x.x * y.den == y.x * x.den and x.y * y.den == y.y * x.den
proc orient(a, b, c: Point): int64 =
  let dx1 = b.x * a.den - a.x * b.den
  let dy1 = b.y * a.den - a.y * b.den
  let dx2 = c.x * b.den - b.x * c.den
  let dy2 = c.y * b.den - b.y * c.den
  dx1 * dy2 - dy1 * dx2
proc lessYx(a, b: Point): bool =
  let y1 = a.y * b.den
  let y2 = b.y * a.den
  if y1 != y2: y1 < y2 else: a.x * b.den < b.x * a.den
proc putI64(outBytes: ptr UncheckedArray[uint8], offset: var int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8:
    outBytes[offset] = uint8((bits shr (8 * b)) and 255)
    inc offset

proc half_plane_intersection*(values: ptr UncheckedArray[int64], n: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "half_plane_intersection".} =
  if values.isNil or n < 1 or n > csize_t(MaxInput): return -1
  if values[0] < 0 or values[0] > 12: return -1
  let count = int(values[0])
  if int(n) != 1 + 3 * count: return -1
  var lines: array[MaxLines, Halfplane]
  var queue: array[MaxLines, Halfplane]
  var points: array[MaxLines, Point]
  var clean: array[MaxLines, Point]
  var lineCount = 0
  for i in 0 ..< count:
    let a = values[1 + 3 * i]
    let b = values[2 + 3 * i]
    let c = values[3 + 3 * i]
    if a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128: return -1
    if (a == 0 and b == 0) or gcd64(a, b) != 1: return -1
    lines[lineCount] = Halfplane(a: a, b: b, c: c)
    inc lineCount
  lines[lineCount] = Halfplane(a: 1, b: 0, c: BoxLimit); inc lineCount
  lines[lineCount] = Halfplane(a: 0, b: 1, c: BoxLimit); inc lineCount
  lines[lineCount] = Halfplane(a: -1, b: 0, c: BoxLimit); inc lineCount
  lines[lineCount] = Halfplane(a: 0, b: -1, c: BoxLimit); inc lineCount
  for i in 1 ..< lineCount:
    let key = lines[i]
    var j = i
    while j > 0 and lineCompare(key, lines[j - 1]) < 0:
      lines[j] = lines[j - 1]
      dec j
    lines[j] = key
  var reduced = 0
  for i in 0 ..< lineCount:
    if reduced > 0 and lines[i].a == lines[reduced - 1].a and lines[i].b == lines[reduced - 1].b: continue
    lines[reduced] = lines[i]
    inc reduced
  var head = 0
  var tail = 0
  for i in 0 ..< reduced:
    let h = lines[i]
    var p: Point
    while tail - head > 1:
      if not intersect(queue[tail - 2], queue[tail - 1], p) or not outside(h, p): break
      dec tail
    while tail - head > 1:
      if not intersect(queue[head], queue[head + 1], p) or not outside(h, p): break
      inc head
    if tail > head:
      let last = queue[tail - 1]
      if last.a * h.b - last.b * h.a == 0:
        if last.a * h.a + last.b * h.b < 0:
          head = 0
          tail = 0
          break
        if h.c < last.c: queue[tail - 1] = h
        continue
    queue[tail] = h
    inc tail
  if tail - head >= 3:
    var p: Point
    while tail - head > 2 and intersect(queue[tail - 2], queue[tail - 1], p) and outside(queue[head], p): dec tail
    while tail - head > 2 and intersect(queue[head], queue[head + 1], p) and outside(queue[tail - 1], p): inc head
  var pointCount = 0
  if tail - head >= 3:
    for i in head ..< tail:
      var p: Point
      if not intersect(queue[i], queue[(if i + 1 == tail: head else: i + 1)], p):
        pointCount = 0
        break
      points[pointCount] = p
      inc pointCount
  var cleanCount = 0
  for i in 0 ..< pointCount:
    if cleanCount == 0 or not samePoint(clean[cleanCount - 1], points[i]):
      clean[cleanCount] = points[i]
      inc cleanCount
  if cleanCount > 1 and samePoint(clean[0], clean[cleanCount - 1]): dec cleanCount
  var changed = true
  while changed and cleanCount >= 3:
    changed = false
    for i in 0 ..< cleanCount:
      let prev = (i + cleanCount - 1) mod cleanCount
      let next = (i + 1) mod cleanCount
      if orient(clean[prev], clean[i], clean[next]) == 0:
        for j in i ..< cleanCount - 1: clean[j] = clean[j + 1]
        dec cleanCount
        changed = true
        break
  if cleanCount < 3: cleanCount = 0
  if cleanCount > 0:
    var first = 0
    for i in 1 ..< cleanCount:
      if lessYx(clean[i], clean[first]): first = i
    let old = clean
    for i in 0 ..< cleanCount: clean[i] = old[(first + i) mod cleanCount]
  let needed = (1 + 4 * cleanCount) * 8
  if csize_t(needed) > capacity or output.isNil: return -2
  var offset = 0
  putI64(output, offset, int64(cleanCount))
  for i in 0 ..< cleanCount:
    let gx = gcd64(clean[i].x, clean[i].den)
    let gy = gcd64(clean[i].y, clean[i].den)
    putI64(output, offset, clean[i].x div gx)
    putI64(output, offset, clean[i].den div gx)
    putI64(output, offset, clean[i].y div gy)
    putI64(output, offset, clean[i].den div gy)
  int64(needed)
