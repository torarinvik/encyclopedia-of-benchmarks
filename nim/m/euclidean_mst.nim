const
  maxPoints = 8
  maxEdges = maxPoints * (maxPoints - 1) div 2
  maxInputLength = 18
  maxOutputWords = 2 * maxPoints - 1

type
  Point = object
    x, y: int64
  Edge = object
    u, v: int
    weight: int64
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc orientation(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc incircle(a, b, c, d: Point): int64 =
  let ax = a.x - d.x
  let ay = a.y - d.y
  let bx = b.x - d.x
  let by = b.y - d.y
  let cx = c.x - d.x
  let cy = c.y - d.y
  (ax * ax + ay * ay) * (bx * cy - by * cx) -
    (bx * bx + by * by) * (ax * cy - ay * cx) +
    (cx * cx + cy * cy) * (ax * by - ay * bx)

proc generalPosition(points: array[maxPoints, Point], count: int): bool =
  for a in 0 ..< count:
    for b in a + 1 ..< count:
      if points[a].x == points[b].x and points[a].y == points[b].y: return false
  for a in 0 ..< count:
    for b in a + 1 ..< count:
      for c in b + 1 ..< count:
        if orientation(points[a], points[b], points[c]) == 0: return false
        for d in 0 ..< count:
          if d != a and d != b and d != c and incircle(points[a], points[b], points[c], points[d]) == 0:
            return false
  true

proc findRoot(parent: var array[maxPoints, int], vertex: int): int =
  var v = vertex
  while parent[v] != v:
    parent[v] = parent[parent[v]]
    v = parent[v]
  v

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc euclidean_mst*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "euclidean_mst".} =
  if input.isNil or length < 1 or length > maxInputLength.csize_t: return -1
  let rawCount = input[0]
  if rawCount < 1'i64 or rawCount > maxPoints or int(length) != 1 + 2 * int(rawCount): return -1
  let count = int(rawCount)
  var points: array[maxPoints, Point]
  for i in 0 ..< count:
    points[i] = Point(x: input[1 + 2 * i], y: input[2 + 2 * i])
    if points[i].x < -10'i64 or points[i].x > 10'i64 or points[i].y < -10'i64 or points[i].y > 10'i64:
      return -1
  if not generalPosition(points, count): return -1
  let outputWords = 2 * count - 1
  let outputBytes = 8 * outputWords
  if output.isNil or outputCapacity < outputBytes.csize_t: return -2

  var candidates: array[maxPoints * maxPoints, bool]
  if count == 2: candidates[1] = true; candidates[maxPoints] = true
  for a in 0 ..< count:
    for b in a + 1 ..< count:
      for c in b + 1 ..< count:
        let turn = orientation(points[a], points[b], points[c])
        var empty = true
        for d in 0 ..< count:
          if d == a or d == b or d == c: continue
          let determinant = incircle(points[a], points[b], points[c], points[d])
          if (determinant > 0) == (turn > 0): empty = false; break
        if empty:
          candidates[a * maxPoints + b] = true; candidates[b * maxPoints + a] = true
          candidates[a * maxPoints + c] = true; candidates[c * maxPoints + a] = true
          candidates[b * maxPoints + c] = true; candidates[c * maxPoints + b] = true
  var edges: array[maxEdges, Edge]
  var edgeCount = 0
  for u in 0 ..< count:
    for v in u + 1 ..< count:
      if candidates[u * maxPoints + v]:
        let dx = points[u].x - points[v].x
        let dy = points[u].y - points[v].y
        let edge = Edge(u: u, v: v, weight: dx * dx + dy * dy)
        var at = edgeCount
        inc edgeCount
        while at > 0:
          let previous = edges[at - 1]
          if previous.weight < edge.weight or (previous.weight == edge.weight and
              (previous.u < edge.u or (previous.u == edge.u and previous.v <= edge.v))): break
          edges[at] = previous
          dec at
        edges[at] = edge
  var parent: array[maxPoints, int]
  var sizes: array[maxPoints, int]
  for i in 0 ..< count: parent[i] = i; sizes[i] = 1
  var words: array[maxOutputWords, int64]
  words[0] = int64(count - 1)
  var selected = 0
  for i in 0 ..< edgeCount:
    if selected == count - 1: break
    var left = findRoot(parent, edges[i].u)
    var right = findRoot(parent, edges[i].v)
    if left == right: continue
    if sizes[left] < sizes[right]: swap(left, right)
    parent[right] = left
    sizes[left] += sizes[right]
    words[1 + 2 * selected] = int64(edges[i].u)
    words[2 + 2 * selected] = int64(edges[i].v)
    inc selected
  if selected != count - 1: return -1
  for word in 0 ..< outputWords: storeI64Le(output, word * 8, words[word])
  int64(outputBytes)
