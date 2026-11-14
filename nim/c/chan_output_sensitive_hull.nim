## Chan hull draft; not compiled or run.
import std/algorithm

type Point = tuple[x, y: int64]

proc turn(a, b, c: Point): int64 =
  (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x)

proc groupHull(points: seq[Point], beginIndex, endIndex: int): seq[int] =
  var order: seq[int] = @[]
  for i in beginIndex ..< endIndex: order.add(i)
  order.sort(proc(a, b: int): int = cmp(points[a], points[b]))
  if order.len == 1: return order
  var lower, upper: seq[int] = @[]
  for id in order:
    while lower.len >= 2 and turn(points[lower[^2]], points[lower[^1]], points[id]) <= 0: discard lower.pop()
    lower.add(id)
  for index in countdown(order.high, 0):
    let id = order[index]
    while upper.len >= 2 and turn(points[upper[^2]], points[upper[^1]], points[id]) <= 0: discard upper.pop()
    upper.add(id)
  discard lower.pop()
  discard upper.pop()
  result = lower & upper

proc tangent(points: seq[Point], hull: seq[int], query: int): int =
  let size = hull.len
  if size == 1: return hull[0]
  if size == 2:
    if turn(points[query], points[hull[0]], points[hull[1]]) > 0: return hull[0]
    return hull[1]
  let initialUp = turn(points[query], points[hull[0]], points[hull[1]]) > 0
  var lo = 0
  var hi = size
  while lo < hi:
    let mid = lo + (hi-lo) div 2
    let lessPrev = turn(points[query], points[hull[mid]], points[hull[(mid+size-1) mod size]]) > 0
    let lessNext = turn(points[query], points[hull[mid]], points[hull[(mid+1) mod size]]) > 0
    if lessPrev and lessNext: return hull[mid]
    let beforeAnchor = mid != 0 and turn(points[query], points[hull[mid]], points[hull[0]]) > 0
    let afterAnchor = mid != 0 and turn(points[query], points[hull[0]], points[hull[mid]]) > 0
    let searchLeft = if initialUp: lessNext and beforeAnchor else: lessNext or afterAnchor
    if searchLeft: hi = mid else: lo = mid+1
  -1

proc chan_output_sensitive_hull*(input: ptr UncheckedArray[int64], length: csize_t,
                                 output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                                 {.cdecl, exportc: "chan_output_sensitive_hull".} =
  if input.isNil or length < 7 or length > 66 or input[0] < 3 or input[0] > 32: return -1
  let n = int(input[0])
  if length != csize_t(1+2*n): return -1
  var points: seq[Point] = @[]
  for i in 0 ..< n:
    let p = (x: input[1+2*i], y: input[2+2*i])
    if p.x < -1000 or p.x > 1000 or p.y < -1000 or p.y > 1000: return -1
    for prior in points:
      if prior == p: return -1
    points.add(p)
  for i in 0 ..< n:
    for j in i+1 ..< n:
      for k in j+1 ..< n:
        if turn(points[i], points[j], points[k]) == 0: return -1
  var start = 0
  for i in 1 ..< n:
    if points[i] < points[start]: start = i
  var guess = min(4, n)
  while true:
    var groups: seq[seq[int]] = @[]
    var groupOf = newSeq[int](n)
    var position = newSeq[int](n)
    for i in 0 ..< n: position[i] = -1
    var beginIndex = 0
    while beginIndex < n:
      let endIndex = min(n, beginIndex + guess)
      let g = groups.len
      for id in beginIndex ..< endIndex: groupOf[id] = g
      groups.add(groupHull(points, beginIndex, endIndex))
      for index, id in groups[^1]: position[id] = index
      beginIndex = endIndex
    var hull = @[start]
    for step in 0 ..< guess:
      let current = hull[^1]
      var candidate = -1
      for g, part in groups:
        var local = -1
        if g == groupOf[current]:
          if position[current] < 0: return -1
          if part.len > 1: local = part[(position[current]+1) mod part.len]
        else:
          local = tangent(points, part, current)
          if local < 0: return -1
        if local >= 0 and (candidate < 0 or turn(points[current], points[candidate], points[local]) < 0): candidate = local
      if candidate < 0: return -1
      if candidate == start:
        let byteCount = 16*hull.len
        if output.isNil or capacity < csize_t(byteCount): return -2
        for i, id in hull:
          for axis in 0 .. 1:
            var bits = cast[uint64](if axis == 0: points[id].x else: points[id].y)
            for b in 0 .. 7:
              output[16*i+8*axis+b] = uint8(bits and 255'u64)
              bits = bits shr 8
        return int64(byteCount)
      if hull.len == n: return -1
      hull.add(candidate)
    if guess == n: return -1
    guess = min(n, guess*guess)
