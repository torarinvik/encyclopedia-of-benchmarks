const maxN = 24
const maxM = 24
const maxQ = 128
const inputMax = 483
const bitStride = maxM + 1

type
  Point = object
    x, y: int64
  Vector = object
    x, y: int64
  Query = object
    a, b, c: int64

proc half(x, y: int64): int =
  if y < 0: return 0
  if y == 0 and x >= 0: return 1
  2

proc angleLess(ax, ay, bx, by: int64): bool =
  let ah = half(ax, ay)
  let bh = half(bx, by)
  if ah != bh: return ah < bh
  ax * by - ay * bx > 0

proc directionLess(a, b: Vector): bool =
  if angleLess(a.x, a.y, b.x, b.y): return true
  if angleLess(b.x, b.y, a.x, a.y): return false
  let ra = a.x*a.x + a.y*a.y
  let rb = b.x*b.x + b.y*b.y
  if ra != rb: return ra < rb
  if a.x != b.x: return a.x < b.x
  a.y < b.y

proc sortVectors(dirs: ptr UncheckedArray[Vector], base, count: int) =
  for i in 1 ..< count:
    let item = dirs[base + i]
    var j = i
    while j > 0 and directionLess(item, dirs[base + j - 1]):
      dirs[base + j] = dirs[base + j - 1]
      dec j
    dirs[base + j] = item

proc lowerRay(dirs: ptr UncheckedArray[Vector], base, count: int, rx, ry: int64): int =
  var low = 0
  var high = count
  while low < high:
    let middle = low + (high - low) div 2
    let v = dirs[base + middle]
    if angleLess(v.x, v.y, rx, ry): low = middle + 1 else: high = middle
  low

proc upperRay(dirs: ptr UncheckedArray[Vector], base, count: int, rx, ry: int64): int =
  var low = 0
  var high = count
  while low < high:
    let middle = low + (high - low) div 2
    let v = dirs[base + middle]
    if not angleLess(rx, ry, v.x, v.y): low = middle + 1 else: high = middle
  low

proc fenwickPrefix(tree: ptr UncheckedArray[int32], base, endIndex: int): int =
  var cursor = endIndex
  while cursor > 0:
    result += int(tree[base + cursor])
    cursor = cursor and (cursor - 1)

proc arcCount(dirs: ptr UncheckedArray[Vector], dirBase, count: int,
    tree: ptr UncheckedArray[int32], bitBase: int, sx, sy, ex, ey: int64): int =
  let left = lowerRay(dirs, dirBase, count, sx, sy)
  let right = upperRay(dirs, dirBase, count, ex, ey)
  if not angleLess(ex, ey, sx, sy):
    return fenwickPrefix(tree, bitBase, right) - fenwickPrefix(tree, bitBase, left)
  fenwickPrefix(tree, bitBase, count) - fenwickPrefix(tree, bitBase, left) + fenwickPrefix(tree, bitBase, right)

proc halfplaneCount(u, v: int, a: array[maxN, Point], dirs: ptr UncheckedArray[Vector],
    counts: array[maxN, int], zeros: array[maxN, int], tree: ptr UncheckedArray[int32]): int =
  let dx = a[v].x - a[u].x
  let dy = a[v].y - a[u].y
  let base = u * maxM
  let bitBase = u * bitStride
  zeros[u] + arcCount(dirs, base, counts[u], tree, bitBase, -dx, -dy, dx, dy)

proc storeLe(output: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc count_points_in_triangle*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "count_points_in_triangle".} =
  if input == nil or length < 3 or length > csize_t(inputMax): return -1
  let nr = input[0]
  let mr = input[1]
  let qr = input[2]
  if nr < 1 or nr > maxN.int64 or mr < 1 or mr > maxM.int64 or qr < 1 or qr > maxQ.int64: return -1
  let n = int(nr)
  let m = int(mr)
  let q = int(qr)
  if int(length) != 3 + 2*n + 2*m + 3*q: return -1
  var a: array[maxN, Point]
  var b: array[maxM, Point]
  var queries: array[maxQ, Query]
  var cursor = 3
  for i in 0 ..< n:
    a[i] = Point(x: input[cursor], y: input[cursor + 1]); cursor += 2
    if abs(a[i].x) > 1_000_000_000 or abs(a[i].y) > 1_000_000_000: return -1
  for i in 0 ..< m:
    b[i] = Point(x: input[cursor], y: input[cursor + 1]); cursor += 2
    if abs(b[i].x) > 1_000_000_000 or abs(b[i].y) > 1_000_000_000: return -1
  for i in 0 ..< q:
    let ia = input[cursor]
    let ib = input[cursor + 1]
    let ic = input[cursor + 2]
    cursor += 3
    if ia < 0 or ia >= nr or ib < 0 or ib >= nr or ic < 0 or ic >= nr: return -1
    queries[i] = Query(a: ia, b: ib, c: ic)
  let required = csize_t(8*q)
  if output == nil or capacity < required: return -2

  var dirs: array[maxN*maxM, Vector]
  var counts: array[maxN, int]
  var zeros: array[maxN, int]
  var bit: array[maxN*bitStride, int32]
  for u in 0 ..< n:
    let base = u*maxM
    for j in 0 ..< m:
      let dx = b[j].x-a[u].x
      let dy = b[j].y-a[u].y
      if dx == 0 and dy == 0: inc zeros[u]
      else:
        dirs[base+counts[u]] = Vector(x: dx, y: dy)
        inc counts[u]
    sortVectors(addr dirs[0], base, counts[u])
    let bitBase = u*bitStride
    for i in 0 ..< counts[u]:
      var at = i+1
      while at <= counts[u]:
        inc bit[bitBase+at]
        at += at and -at
  var answers: array[maxQ, int64]
  for qi in 0 ..< q:
    var ia = int(queries[qi].a)
    var ib = int(queries[qi].b)
    var ic = int(queries[qi].c)
    let orient = (a[ib].x-a[ia].x)*(a[ic].y-a[ia].y) - (a[ib].y-a[ia].y)*(a[ic].x-a[ia].x)
    if orient == 0: answers[qi] = 0; continue
    if orient < 0: swap(ib, ic)
    let outside = halfplaneCount(ia,ib,a,addr dirs[0],counts,zeros,addr bit[0]) + halfplaneCount(ib,ic,a,addr dirs[0],counts,zeros,addr bit[0]) + halfplaneCount(ic,ia,a,addr dirs[0],counts,zeros,addr bit[0])
    let bb = ib*maxM; let cb = ic*maxM; let ab = ia*maxM
    let bt = ib*bitStride; let ct = ic*bitStride; let at = ia*bitStride
    let pairs = zeros[ib] + arcCount(addr dirs[0],bb,counts[ib],addr bit[0],bt,a[ib].x-a[ic].x,a[ib].y-a[ic].y,a[ib].x-a[ia].x,a[ib].y-a[ia].y)
      + zeros[ic] + arcCount(addr dirs[0],cb,counts[ic],addr bit[0],ct,a[ic].x-a[ia].x,a[ic].y-a[ia].y,a[ic].x-a[ib].x,a[ic].y-a[ib].y)
      + zeros[ia] + arcCount(addr dirs[0],ab,counts[ia],addr bit[0],at,a[ia].x-a[ib].x,a[ia].y-a[ib].y,a[ia].x-a[ic].x,a[ia].y-a[ic].y)
    answers[qi] = int64(m-outside+pairs)
  for i in 0 ..< q: storeLe(output,8*i,answers[i])
  int64(required)
