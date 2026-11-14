## Unverified divide-and-conquer tangent-merge hull draft.
import std/algorithm

type Point = tuple[x, y: int64]

proc cross(a, b, c: Point): int64 =
  (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)

proc chain(points: seq[Point], order: seq[int], lo, hi: int, upper: bool): seq[int] =
  if hi-lo == 1: return @[order[lo]]
  let middle = lo+(hi-lo) div 2
  let left = chain(points, order, lo, middle, upper)
  let right = chain(points, order, middle, hi, upper)
  var i = left.high
  var j = 0
  var changed = true
  while changed:
    changed = false
    while i > 0:
      let sign = cross(points[left[i]], points[right[j]], points[left[i-1]])
      if (upper and sign <= 0) or (not upper and sign >= 0): break
      dec i
      changed = true
    while j+1 < right.len:
      let sign = cross(points[left[i]], points[right[j]], points[right[j+1]])
      if (upper and sign <= 0) or (not upper and sign >= 0): break
      inc j
      changed = true
  for k in 0 .. i: result.add(left[k])
  for k in j ..< right.len: result.add(right[k])

proc divide_conquer_tangent_hull*(input: ptr UncheckedArray[int64], length: csize_t,
                                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                                 {.cdecl, exportc: "divide_conquer_tangent_hull".} =
  if input.isNil or length < 7 or length > 66 or input[0] < 3 or input[0] > 32: return -1
  let n = int(input[0])
  if length != csize_t(1+2*n): return -1
  var points: seq[Point] = @[]
  var order: seq[int] = @[]
  for i in 0 ..< n:
    let point = (x: input[1+2*i], y: input[2+2*i])
    if point.x < -1000 or point.x > 1000 or point.y < -1000 or point.y > 1000: return -1
    for other in points:
      if point.x == other.x: return -1
    points.add(point)
    order.add(i)
  for i in 0 ..< n:
    for j in i+1 ..< n:
      for k in j+1 ..< n:
        if cross(points[i], points[j], points[k]) == 0: return -1
  order.sort(proc(a, b: int): int = cmp(points[a].x, points[b].x))
  var hull = chain(points, order, 0, n, false)
  let upper = chain(points, order, 0, n, true)
  var i = upper.high
  while i > 1:
    dec i
    hull.add(upper[i])
  let byteCount = 16*hull.len
  if output.isNil or capacity < csize_t(byteCount): return -2
  for index, id in hull:
    for axis in 0 .. 1:
      var bits = cast[uint64](if axis == 0: points[id].x else: points[id].y)
      for b in 0 .. 7:
        output[16*index+8*axis+b] = uint8(bits and 255'u64)
        bits = bits shr 8
  return int64(byteCount)
