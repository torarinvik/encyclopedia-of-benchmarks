import std/[algorithm, math, sets, sequtils]

const
  MaxN = 8
  MaxEdges = 18
  MaxInput = 55
  MaxStack = 64

type
  Point = tuple[x, y: int64]
  Edge = tuple[u, v: int]
  Face = tuple[a, b, c: int]
  State = object
    n: int
    points: array[MaxN, Point]
    edges: seq[Edge]
    faces: HashSet[Face]
    rotation: array[MaxN, seq[int]]
    treeRotation: array[MaxN, seq[int]]
    contour: seq[Edge]
    stack: seq[Edge]
    weights: array[MaxN, array[MaxN, float64]]
    hull: array[MaxN, bool]
    tree: array[MaxN, array[MaxN, bool]]
    kept: array[MaxN, array[MaxN, bool]]

proc orient(a, b, c: Point): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc incircle(a, b, c, p: Point): int64 =
  let ax = a.x - p.x; let ay = a.y - p.y
  let bx = b.x - p.x; let by = b.y - p.y
  let cx = c.x - p.x; let cy = c.y - p.y
  (ax * ax + ay * ay) * (bx * cy - by * cx) -
    (bx * bx + by * by) * (ax * cy - ay * cx) +
    (cx * cx + cy * cy) * (ax * by - ay * bx)

proc dist2(points: array[MaxN, Point], a, b: int): int64 =
  let dx = points[a].x - points[b].x; let dy = points[a].y - points[b].y
  dx * dx + dy * dy

proc canonFace(a, b, c: int): Face =
  var values = [a, b, c]
  values.sort()
  (values[0], values[1], values[2])

proc edgeLess(a, b: Edge): bool =
  a.u < b.u or (a.u == b.u and a.v < b.v)

proc half(dx, dy: int64): int =
  if dy > 0 or (dy == 0 and dx >= 0): 0 else: 1

proc angleCompare(points: array[MaxN, Point], origin, a, b: int): int =
  let ax = points[a].x - points[origin].x; let ay = points[a].y - points[origin].y
  let bx = points[b].x - points[origin].x; let by = points[b].y - points[origin].y
  let ah = half(ax, ay); let bh = half(bx, by)
  if ah != bh: return cmp(ah, bh)
  let cross = ax * by - ay * bx
  if cross != 0: return (if cross > 0: -1 else: 1)
  cmp(a, b)

proc findDart(boundary: seq[Edge], dart: Edge): int =
  for i, edge in boundary:
    if edge == dart: return i
  -1

proc canonicalize(boundary: var seq[Edge]) =
  if boundary.len == 0: return
  var first = 0
  for i in 1 ..< boundary.len:
    if edgeLess(boundary[i], boundary[first]): first = i
  if first > 0:
    var rotated = newSeqOfCap[Edge](boundary.len)
    for i in 0 ..< boundary.len: rotated.add(boundary[(first + i) mod boundary.len])
    boundary = rotated

proc clockwiseNext(s: State, u, v: int): int =
  let at = s.rotation[v].find(u)
  if at < 0: return -1
  s.rotation[v][(at + s.rotation[v].len - 1) mod s.rotation[v].len]

proc treeClockwiseNext(s: State, u, v: int): int =
  let at = s.treeRotation[v].find(u)
  if at < 0: return -1
  s.treeRotation[v][(at + s.treeRotation[v].len - 1) mod s.treeRotation[v].len]

proc isEligible(s: State, dart: Edge): bool =
  let at = findDart(s.contour, dart)
  if at < 0 or s.hull[dart.v] or s.contour.len < 3: return false
  let next = s.contour[(at + 1) mod s.contour.len]
  let neighbor = clockwiseNext(s, dart.u, dart.v)
  next.u == dart.v and next.v == neighbor and
    s.faces.contains(canonFace(dart.u, dart.v, neighbor))

proc parse(s: var State, input: ptr UncheckedArray[int64], length: csize_t): bool =
  if input.isNil or length < csize_t(14) or length > csize_t(MaxInput): return false
  let n64 = input[0]
  if n64 < 3 or n64 > int64(MaxN): return false
  s.n = int(n64)
  let mAt = 1 + 2 * s.n
  if length <= csize_t(mAt): return false
  let m64 = input[mAt]
  if m64 < 3 or m64 > int64(MaxEdges) or int64(length) != mAt + 1 + 2 * m64: return false
  for i in 0 ..< s.n:
    let point: Point = (x: input[1 + 2 * i], y: input[2 + 2 * i])
    if point.x < -10 or point.x > 10 or point.y < -10 or point.y > 10: return false
    for j in 0 ..< i:
      if s.points[j] == point: return false
    s.points[i] = point
  for a in 0 ..< s.n:
    for b in a + 1 ..< s.n:
      for c in b + 1 ..< s.n:
        if orient(s.points[a], s.points[b], s.points[c]) == 0: return false
  for a in 0 ..< s.n:
    for b in a + 1 ..< s.n:
      for c in b + 1 ..< s.n:
        for d in c + 1 ..< s.n:
          if incircle(s.points[a], s.points[b], s.points[c], s.points[d]) == 0: return false
  for i in 0 ..< int(m64):
    let u = input[mAt + 1 + 2 * i]; let v = input[mAt + 2 + 2 * i]
    if u < 0 or v <= u or v >= n64: return false
    let edge: Edge = (u: int(u), v: int(v))
    if s.edges.len > 0 and not edgeLess(s.edges[^1], edge): return false
    s.edges.add(edge)

  s.faces = initHashSet[Face]()
  var expectedEdges = initHashSet[Edge]()
  for a0 in 0 ..< s.n:
    for b0 in a0 + 1 ..< s.n:
      for c0 in b0 + 1 ..< s.n:
        var a = a0; var b = b0; var c = c0
        if orient(s.points[a], s.points[b], s.points[c]) < 0: swap(b, c)
        var empty = true
        for p in 0 ..< s.n:
          if p != a and p != b and p != c and incircle(s.points[a], s.points[b], s.points[c], s.points[p]) > 0:
            empty = false
        if empty:
          s.faces.incl(canonFace(a, b, c))
          expectedEdges.incl((u: min(a, b), v: max(a, b)))
          expectedEdges.incl((u: min(a, c), v: max(a, c)))
          expectedEdges.incl((u: min(b, c), v: max(b, c)))
  if expectedEdges.len != s.edges.len: return false
  for edge in s.edges:
    if not expectedEdges.contains(edge): return false

  for a in 0 ..< s.n:
    for b in a + 1 ..< s.n:
      var positive = false; var negative = false
      for p in 0 ..< s.n:
        if p == a or p == b: continue
        let side = orient(s.points[a], s.points[b], s.points[p])
        positive = positive or side > 0; negative = negative or side < 0
      if not (positive and negative): s.hull[a] = true; s.hull[b] = true
  for (u, v) in s.edges:
    s.rotation[u].add(v); s.rotation[v].add(u)
  for v in 0 ..< s.n:
    s.rotation[v].sort(proc(a, b: int): int = angleCompare(s.points, v, a, b))
  true

proc buildTree(s: var State): bool =
  var ordered = s.edges
  ordered.sort(proc(a, b: Edge): int =
    let da = dist2(s.points, a.u, a.v); let db = dist2(s.points, b.u, b.v)
    if da != db: cmp(da, db)
    elif a.u != b.u: cmp(a.u, b.u)
    else: cmp(a.v, b.v))
  var parent: array[MaxN, int]
  var sizes: array[MaxN, int]
  for i in 0 ..< s.n: parent[i] = i; sizes[i] = 1
  proc root(v0: int): int =
    var v = v0
    while parent[v] != v:
      parent[v] = parent[parent[v]]
      v = parent[v]
    v
  for edge in ordered:
    var a = root(edge.u); var b = root(edge.v)
    if a == b: continue
    if sizes[a] < sizes[b]: swap(a, b)
    parent[b] = a; sizes[a] += sizes[b]
    s.tree[edge.u][edge.v] = true; s.tree[edge.v][edge.u] = true
    s.kept[edge.u][edge.v] = true; s.kept[edge.v][edge.u] = true
    s.treeRotation[edge.u].add(edge.v); s.treeRotation[edge.v].add(edge.u)
  var treeCount = 0
  for u in 0 ..< s.n:
    for v in u + 1 ..< s.n:
      if s.tree[u][v]: inc treeCount
  if treeCount != s.n - 1: return false
  for v in 0 ..< s.n:
    s.treeRotation[v].sort(proc(a, b: int): int = angleCompare(s.points, v, a, b))
  for edge in s.edges:
    let length = sqrt(float64(dist2(s.points, edge.u, edge.v)))
    s.weights[edge.u][edge.v] = length; s.weights[edge.v][edge.u] = length
  var seed: Edge = (u: MaxN, v: MaxN)
  for u in 0 ..< s.n:
    for v in 0 ..< s.n:
      let dart: Edge = (u: u, v: v)
      if s.tree[u][v] and edgeLess(dart, seed): seed = dart
  if seed.u == MaxN: return false
  s.contour.add(seed)
  let expected = 2 * treeCount
  while true:
    let last = s.contour[^1]
    let next = treeClockwiseNext(s, last.u, last.v)
    if next < 0: return false
    let dart: Edge = (u: last.v, v: next)
    if dart == seed: break
    if findDart(s.contour, dart) >= 0 or s.contour.len >= expected: return false
    s.contour.add(dart)
  s.contour.len == expected

proc runAlgorithm(s: var State, absorbed, shortcuts: var int): bool =
  for dart in s.contour:
    if s.isEligible(dart): s.stack.add(dart)
  var steps = 0
  while s.stack.len > 0 and steps < 2 * MaxEdges:
    let dart = s.stack.pop()
    if not s.isEligible(dart): continue
    let at = findDart(s.contour, dart)
    let nextAt = (at + 1) mod s.contour.len
    let v = dart.u; let w = dart.v; let u = s.contour[nextAt].v
    let pathWeight = s.weights[v][w] + s.weights[w][u]
    let direct = sqrt(float64(dist2(s.points, v, u)))
    if pathWeight > 2.0 * direct:
      s.kept[v][u] = true; s.kept[u][v] = true
    else:
      s.weights[v][u] = pathWeight
    let chord: Edge = (u: v, v: u)
    if nextAt == 0:
      s.contour.delete(at); s.contour.delete(0); s.contour.add(chord)
    else:
      s.contour[at] = chord; s.contour.delete(nextAt)
    canonicalize(s.contour)
    inc absorbed; inc steps
    let chordAt = findDart(s.contour, chord)
    if chordAt < 0: return false
    if s.isEligible(chord): s.stack.add(chord)
    let leftAt = (chordAt + s.contour.len - 1) mod s.contour.len
    let left = s.contour[leftAt]
    if s.isEligible(left): s.stack.add(left)
  if steps >= 2 * MaxEdges and s.stack.len > 0: return false
  var edgeCount = 0
  for u in 0 ..< s.n:
    for v in u + 1 ..< s.n:
      if s.kept[u][v]: inc edgeCount
  shortcuts = edgeCount - (s.n - 1)
  true

proc storeI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8(bits and 255)
    bits = bits shr 8

proc levcopoulos_lingas_planar_geometric_spanner*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "levcopoulos_lingas_planar_geometric_spanner".} =
  var state: State
  if not parse(state, input, length) or not buildTree(state): return -1
  var absorbed = 0; var shortcuts = 0
  if not runAlgorithm(state, absorbed, shortcuts): return -1
  var words: array[3 + 2 * MaxEdges, int64]
  var count = 3
  words[0] = int64(absorbed); words[1] = int64(shortcuts)
  for u in 0 ..< state.n:
    for v in u + 1 ..< state.n:
      if state.kept[u][v]:
        words[count] = int64(u); words[count + 1] = int64(v)
        count += 2; inc words[2]
  let bytes = count * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< count: storeI64(output, i, words[i])
  int64(bytes)
