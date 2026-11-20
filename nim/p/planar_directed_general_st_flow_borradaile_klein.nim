const MaxN = 6
const MaxM = 10
const MaxDarts = 20
const MaxFaces = 10
const MaxInput = 61
const MaxAugmentations = 25
const Inf = high(int64) div 4

type Graph = object
  n, m, source, sink: int
  tail, head, capacity: array[MaxM, int]
  degree: array[MaxN, int]
  rotation: array[MaxN, array[MaxN, int]]
  localPos: array[MaxN, array[MaxM, int]]
  leftFace, rightFace: array[MaxDarts, int]
  faces, infinityFace, rootAnchor: int

proc dartHead(g: Graph, dart: int): int =
  let e = dart div 2
  if (dart and 1) == 0: g.head[e] else: g.tail[e]

proc leftSuccessor(g: Graph, dart: int): int =
  let vertex = dartHead(g, dart)
  let edge = dart div 2
  let degree = g.degree[vertex]
  let position = g.localPos[vertex][edge]
  if degree <= 0 or position < 0: return -1
  let prior = g.rotation[vertex][(position + degree - 1) mod degree]
  2 * prior + ord(g.head[prior] == vertex)

proc decode(a: openArray[int64], g: var Graph): bool =
  if a.len < 4 or a.len > MaxInput: return false
  let n0 = a[0]; let m0 = a[1]; let s0 = a[2]; let t0 = a[3]
  if n0 < 2 or n0 > MaxN or m0 < 1 or m0 > MaxM or s0 < 0 or s0 >= n0 or t0 < 0 or t0 >= n0 or s0 == t0: return false
  g.n = int(n0); g.m = int(m0); g.source = int(s0); g.sink = int(t0)
  if a.len < 4 + 3 * g.m: return false
  var pairs: array[MaxN, array[MaxN, bool]]
  var at = 4
  for e in 0 ..< g.m:
    let u0 = a[at]; let v0 = a[at + 1]; let c0 = a[at + 2]; at += 3
    if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or c0 < 1 or c0 > 5: return false
    let u = int(u0); let v = int(v0)
    if pairs[u][v] or pairs[v][u]: return false
    pairs[u][v] = true; pairs[v][u] = true
    g.tail[e] = u; g.head[e] = v; g.capacity[e] = int(c0)
  var occurrence: array[MaxM, array[2, int]]
  var used: array[MaxN, array[MaxM, bool]]
  for x in 0 ..< g.n:
    for e in 0 ..< g.m: g.localPos[x][e] = -1
  for x in 0 ..< g.n:
    if at >= a.len: return false
    let d0 = a[at]; at += 1
    if d0 < 1 or d0 >= n0 or at + int(d0) > a.len: return false
    g.degree[x] = int(d0)
    for j in 0 ..< g.degree[x]:
      let e0 = a[at]; at += 1
      if e0 < 0 or e0 >= m0: return false
      let e = int(e0)
      if used[x][e]: return false
      used[x][e] = true; g.rotation[x][j] = e; g.localPos[x][e] = j
      if g.tail[e] == x: inc occurrence[e][0]
      elif g.head[e] == x: inc occurrence[e][1]
      else: return false
  if at != a.len: return false
  for e in 0 ..< g.m:
    if occurrence[e][0] != 1 or occurrence[e][1] != 1: return false

  var adjacent: array[MaxN, array[MaxN, bool]]
  for e in 0 ..< g.m:
    adjacent[g.tail[e]][g.head[e]] = true; adjacent[g.head[e]][g.tail[e]] = true
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var qh = 0; var qt = 1; seen[g.source] = true; queue[0] = g.source
  while qh < qt:
    let x = queue[qh]; inc qh
    for y in 0 ..< g.n:
      if adjacent[x][y] and not seen[y]: seen[y] = true; queue[qt] = y; inc qt
  for x in 0 ..< g.n:
    if not seen[x]: return false

  for d in 0 ..< 2 * g.m: g.leftFace[d] = -1
  g.faces = 0
  for start in 0 ..< 2 * g.m:
    if g.leftFace[start] >= 0: continue
    var dart = start
    while g.leftFace[dart] < 0:
      g.leftFace[dart] = g.faces
      dart = leftSuccessor(g, dart)
      if dart < 0: return false
    if dart != start: return false
    inc g.faces
  if g.faces != g.m - g.n + 2: return false
  for d in 0 ..< 2 * g.m: g.rightFace[d] = g.leftFace[d xor 1]
  g.rootAnchor = g.rotation[g.sink][0]
  let rootDart = 2 * g.rootAnchor + ord(g.head[g.rootAnchor] == g.sink)
  g.infinityFace = g.rightFace[rootDart]
  true

proc rightFirst(g: var Graph, vertex, anchor: int, root: bool,
    residual: var array[MaxN, array[MaxN, int]], seen: var array[MaxN, bool], parent: var array[MaxN, int]) =
  let degree = g.degree[vertex]
  let position = g.localPos[vertex][anchor]
  let first = if root: 0 else: 1
  for step in first ..< first + degree:
    let edge = g.rotation[vertex][(position + step) mod degree]
    let neighbor = if g.tail[edge] == vertex: g.head[edge] else: g.tail[edge]
    if not seen[neighbor] and residual[neighbor][vertex] > 0:
      seen[neighbor] = true; parent[neighbor] = vertex
      rightFirst(g, neighbor, edge, false, residual, seen, parent)

proc solve(g: var Graph): int64 =
  var dual: array[MaxFaces, array[MaxFaces, int64]]
  var distance: array[MaxFaces, int64]
  var settled: array[MaxFaces, bool]
  for f in 0 ..< MaxFaces:
    distance[f] = Inf
    for h in 0 ..< MaxFaces: dual[f][h] = Inf
  for d in 0 ..< 2 * g.m:
    let fromFace = g.rightFace[d]; let toFace = g.leftFace[d]
    let weight = if (d and 1) == 0: int64(g.capacity[d div 2]) else: 0'i64
    dual[fromFace][toFace] = min(dual[fromFace][toFace], weight)
  distance[g.infinityFace] = 0
  for _ in 0 ..< g.faces:
    var current = -1
    for f in 0 ..< g.faces:
      if not settled[f] and (current < 0 or distance[f] < distance[current]): current = f
    if current < 0 or distance[current] == Inf: break
    settled[current] = true
    for next in 0 ..< g.faces:
      if dual[current][next] != Inf: distance[next] = min(distance[next], distance[current] + dual[current][next])
  var residual: array[MaxN, array[MaxN, int]]
  for e in 0 ..< g.m:
    let eta = distance[g.leftFace[2 * e]] - distance[g.rightFace[2 * e]]
    if eta < 0 or eta > g.capacity[e]: return -1
    residual[g.tail[e]][g.head[e]] += g.capacity[e] - int(eta)
    residual[g.head[e]][g.tail[e]] += int(eta)
  var total = 0'i64
  for augmentation in 0 .. MaxAugmentations:
    var seen: array[MaxN, bool]
    var parent: array[MaxN, int]
    for x in 0 ..< g.n: parent[x] = -1
    seen[g.sink] = true
    rightFirst(g, g.sink, g.rootAnchor, true, residual, seen, parent)
    if not seen[g.source]: return total
    if augmentation == MaxAugmentations: return -1
    var delta = high(int)
    var x = g.source
    while x != g.sink:
      let y = parent[x]; delta = min(delta, residual[x][y]); x = y
    x = g.source
    while x != g.sink:
      let y = parent[x]; residual[x][y] -= delta; residual[y][x] += delta; x = y
    total += int64(delta)
  -1

proc planar_directed_general_st_flow_borradaile_klein*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  var g: Graph
  if not decode(input.toOpenArray(0, int(length) - 1), g): return -1
  let value = solve(g)
  if value < 0: return -1
  if output == nil or capacity < 8: return -2
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[i] = uint8((bits shr (8 * i)) and 255)
  8
