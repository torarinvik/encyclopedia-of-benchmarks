import std/options

const
  MaxN = 8
  MaxM = 18
  MaxF = 12
  MaxInput = 55
  MaxOutput = 128

type
  Graph = object
    n, k, b, m, f, center, outerId: int
    outer: array[MaxN, int]
    degree: array[MaxN, int]
    rotation: array[MaxN, array[MaxN, int]]
    permutation: array[MaxN, int]
    adjacent: array[MaxN, array[MaxN, bool]]
    edges: array[MaxM, tuple[u, v: int]]
    faceLen: array[MaxF, int]
    face: array[MaxF, array[MaxN, int]]
    dartFace: array[MaxN, array[MaxN, int]]

proc connectedWithout(g: Graph, removedA, removedB: int): bool =
  var start = -1
  var expected = 0
  for v in 0 ..< g.n:
    if v != removedA and v != removedB:
      if start < 0: start = v
      inc expected
  if expected <= 1: return true
  var seen: array[MaxN, bool]
  var stack: array[MaxN, int]
  var top = 1
  var count = 0
  stack[0] = start
  seen[start] = true
  while top > 0:
    dec top
    let u = stack[top]
    inc count
    for v in 0 ..< g.n:
      if v != removedA and v != removedB and g.adjacent[u][v] and not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  count == expected

proc faceWalk(g: Graph, first, second: int): Option[seq[int]] =
  var seen: array[MaxN, array[MaxN, bool]]
  var cycle: seq[int] = @[]
  var u = first
  var v = second
  for _ in 0 ..< 2 * g.m:
    if not g.adjacent[u][v] or seen[u][v]: return none(seq[int])
    seen[u][v] = true
    cycle.add(u)
    var at = -1
    for i in 0 ..< g.degree[v]:
      if g.rotation[v][i] == u: at = i
    if at < 0: return none(seq[int])
    let next = g.rotation[v][(at + 1) mod g.degree[v]]
    u = v
    v = next
    if u == first and v == second: return some(cycle)
  none(seq[int])

proc sameCycle(a, b: openArray[int]): bool =
  if a.len != b.len: return false
  for shift in 0 ..< b.len:
    var same = true
    for i in 0 ..< a.len:
      if a[i] != b[(i + shift) mod b.len]: same = false
    if same: return true
  false

proc parse(values: openArray[int64]): Option[Graph] =
  if values.len < 3 or values.len > MaxInput: return none(Graph)
  if values[0] < 4 or values[0] > MaxN or values[1] < 3 or values[1] > MaxN or
      (values[0] - 1) mod values[1] != 0 or
      values[2] < values[1] or values[2] > values[0] or values[2] mod values[1] != 0:
    return none(Graph)
  var g: Graph
  g.n = int(values[0]); g.k = int(values[1]); g.b = int(values[2])
  var offset = 3
  if offset + g.b > values.len: return none(Graph)
  var outerSeen: array[MaxN, bool]
  for i in 0 ..< g.b:
    let raw = values[offset]
    inc offset
    if raw < 0 or raw >= values[0]: return none(Graph)
    let v = int(raw)
    if outerSeen[v]: return none(Graph)
    outerSeen[v] = true
    g.outer[i] = v
  var degreeSum = 0
  for u in 0 ..< g.n:
    if offset >= values.len: return none(Graph)
    let degreeRaw = values[offset]
    inc offset
    if degreeRaw < 3 or degreeRaw >= values[0] or offset + int(degreeRaw) > values.len:
      return none(Graph)
    let d = int(degreeRaw)
    g.degree[u] = d
    degreeSum += d
    var rowSeen: array[MaxN, bool]
    for i in 0 ..< d:
      let raw = values[offset]
      inc offset
      if raw < 0 or raw >= values[0] or raw == int64(u): return none(Graph)
      let v = int(raw)
      if rowSeen[v]: return none(Graph)
      rowSeen[v] = true
      g.rotation[u][i] = v
      g.adjacent[u][v] = true
  if offset + g.n != values.len or degreeSum mod 2 != 0: return none(Graph)
  var permSeen: array[MaxN, bool]
  for u in 0 ..< g.n:
    let raw = values[offset + u]
    if raw < 0 or raw >= values[0]: return none(Graph)
    let v = int(raw)
    if permSeen[v]: return none(Graph)
    permSeen[v] = true
    g.permutation[u] = v
  g.m = degreeSum div 2
  if g.m < g.n or g.m > 3 * g.n - 6 or g.m > MaxM: return none(Graph)
  var edgeCount = 0
  for u in 0 ..< g.n:
    for v in 0 ..< g.n:
      if g.adjacent[u][v] != g.adjacent[v][u]: return none(Graph)
      if u < v and g.adjacent[u][v]:
        g.edges[edgeCount] = (u, v)
        inc edgeCount
  if edgeCount != g.m or not connectedWithout(g, -1, -1): return none(Graph)
  for u in 0 ..< g.n:
    if not connectedWithout(g, u, -1): return none(Graph)
    for v in u + 1 ..< g.n:
      if not connectedWithout(g, u, v): return none(Graph)

  for u in 0 ..< MaxN:
    for v in 0 ..< MaxN: g.dartFace[u][v] = -1
  for e in 0 ..< g.m:
    let (a, b) = g.edges[e]
    for (u, v) in [(a, b), (b, a)]:
      if g.dartFace[u][v] >= 0: continue
      if g.f >= MaxF: return none(Graph)
      let cycleOpt = faceWalk(g, u, v)
      if cycleOpt.isNone: return none(Graph)
      let cycle = cycleOpt.get
      if cycle.len < 3 or cycle.len > g.n: return none(Graph)
      var faceSeen: array[MaxN, bool]
      for i, x in cycle:
        let y = cycle[(i + 1) mod cycle.len]
        if faceSeen[x] or g.dartFace[x][y] >= 0: return none(Graph)
        faceSeen[x] = true
      g.faceLen[g.f] = cycle.len
      for i, x in cycle:
        let y = cycle[(i + 1) mod cycle.len]
        g.face[g.f][i] = x
        g.dartFace[x][y] = g.f
      inc g.f
  if g.f != g.m - g.n + 2: return none(Graph)
  g.outerId = -1
  for f in 0 ..< g.f:
    if g.faceLen[f] == g.b and sameCycle(g.outer.toOpenArray(0, g.b - 1), g.face[f].toOpenArray(0, g.b - 1)):
      g.outerId = f
  if g.outerId < 0: return none(Graph)
  var fixedCount = 0
  for v in 0 ..< g.n:
    if g.permutation[v] == v:
      g.center = v
      inc fixedCount
  if fixedCount != 1 or outerSeen[g.center]: return none(Graph)
  for v in 0 ..< g.n:
    if v == g.center: continue
    var current = g.permutation[v]
    var orbitLength = 1
    while current != v and orbitLength <= g.k:
      current = g.permutation[current]
      inc orbitLength
    if current != v or orbitLength != g.k: return none(Graph)
  var power: array[MaxN, int]
  for v in 0 ..< g.n: power[v] = v
  for exponent in 1 .. g.k:
    var next: array[MaxN, int]
    var identity = true
    for v in 0 ..< g.n:
      next[v] = g.permutation[power[v]]
      if next[v] != v: identity = false
    if identity != (exponent == g.k): return none(Graph)
    power = next
  for u in 0 ..< g.n:
    let image = g.permutation[u]
    for v in 0 ..< g.n:
      if g.adjacent[u][v] != g.adjacent[image][g.permutation[v]]: return none(Graph)
    var rowOk = false
    for shift in 0 ..< g.degree[image]:
      var equal = true
      for i in 0 ..< g.degree[u]:
        if g.permutation[g.rotation[u][i]] != g.rotation[image][(i + shift) mod g.degree[image]]:
          equal = false
      if equal: rowOk = true
    if not rowOk: return none(Graph)
  let shift = g.b div g.k
  for i in 0 ..< g.b:
    if g.permutation[g.outer[i]] != g.outer[(i + shift) mod g.b]: return none(Graph)
  some(g)

proc solve(g: Graph): Option[seq[int64]] =
  var distance: array[MaxN, int]
  for v in 0 ..< MaxN: distance[v] = -1
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  distance[g.center] = 0
  queue[0] = g.center
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< g.n:
      if g.adjacent[u][v] and distance[v] < 0:
        distance[v] = distance[u] + 1
        queue[tail] = v
        inc tail
  var endpoint = -1
  for i in 0 ..< g.b:
    let v = g.outer[i]
    if endpoint < 0 or distance[v] < distance[endpoint] or (distance[v] == distance[endpoint] and v < endpoint):
      endpoint = v
  if endpoint < 0 or distance[endpoint] <= 0: return none(seq[int64])
  var toEnd: array[MaxN, int]
  for v in 0 ..< MaxN: toEnd[v] = -1
  head = 0; tail = 1; toEnd[endpoint] = 0; queue[0] = endpoint
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< g.n:
      if g.adjacent[u][v] and toEnd[v] < 0:
        toEnd[v] = toEnd[u] + 1
        queue[tail] = v
        inc tail
  var p1 = @[g.center]
  while p1[^1] != endpoint:
    let u = p1[^1]
    var choice = -1
    for v in 0 ..< g.n:
      if g.adjacent[u][v] and toEnd[v] == toEnd[u] - 1 and (choice < 0 or v < choice): choice = v
    if choice < 0 or p1.len >= MaxN: return none(seq[int64])
    p1.add(choice)
  if p1.len - 1 != distance[endpoint]: return none(seq[int64])
  var p2: seq[int] = @[]
  for v in p1: p2.add(g.permutation[v])
  let endpoint2 = p2[^1]
  if endpoint2 == endpoint: return none(seq[int64])
  for i in 1 ..< p1.len:
    for j in 1 ..< p2.len:
      if p1[i] == p2[j]: return none(seq[int64])
  for i in 1 ..< p1.len - 1:
    for j in 0 ..< g.b:
      if p1[i] == g.outer[j] or p2[i] == g.outer[j]: return none(seq[int64])
  var start = -1
  for i in 0 ..< g.b:
    if g.outer[i] == endpoint: start = i
  if start < 0: return none(seq[int64])
  var p0: seq[int] = @[]
  for i in 0 .. g.b div g.k: p0.add(g.outer[(start + i) mod g.b])
  if p0[^1] != endpoint2: return none(seq[int64])
  var cycle: seq[int] = @[]
  for v in p1: cycle.add(v)
  for i in 1 ..< p0.len: cycle.add(p0[i])
  if p2.len >= 2:
    for i in countdown(p2.len - 2, 0): cycle.add(p2[i])
  if cycle[0] != g.center or cycle[^1] != g.center: return none(seq[int64])
  var seenVertex: array[MaxN, bool]
  var cut: array[MaxN, array[MaxN, bool]]
  for i in 0 ..< cycle.len - 1:
    let u = cycle[i]
    let v = cycle[i + 1]
    if not g.adjacent[u][v] or seenVertex[u]: return none(seq[int64])
    seenVertex[u] = true
    cut[u][v] = true
    cut[v][u] = true
  let seed = g.dartFace[p0[1]][p0[0]]
  if seed < 0 or seed == g.outerId: return none(seq[int64])
  var dual: array[MaxF, array[MaxF, bool]]
  for e in 0 ..< g.m:
    let (u, v) = g.edges[e]
    if cut[u][v]: continue
    let a = g.dartFace[u][v]
    let b = g.dartFace[v][u]
    dual[a][b] = true
    dual[b][a] = true
  var inside: array[MaxF, bool]
  head = 0; tail = 1; queue[0] = seed; inside[seed] = true
  while head < tail:
    let f = queue[head]
    inc head
    for other in 0 ..< g.f:
      if dual[f][other] and not inside[other]:
        inside[other] = true
        queue[tail] = other
        inc tail
  if inside[g.outerId]: return none(seq[int64])
  var vertices = seenVertex
  for f in 0 ..< g.f:
    if inside[f]:
      for i in 0 ..< g.faceLen[f]: vertices[g.face[f][i]] = true
  var vertexMask = 0'i64
  var edgeMask = 0'i64
  for v in 0 ..< g.n:
    if vertices[v]: vertexMask = vertexMask or (1'i64 shl v)
  for e in 0 ..< g.m:
    let (u, v) = g.edges[e]
    if vertices[u] and vertices[v]: edgeMask = edgeMask or (1'i64 shl e)
  var words: seq[int64] = @[int64(p1.len)]
  for v in p1: words.add(int64(v))
  words.add(int64(p2.len))
  for v in p2: words.add(int64(v))
  words.add(int64(p0.len))
  for v in p0: words.add(int64(v))
  words.add(vertexMask); words.add(edgeMask)
  some(words)

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[offset + i] = uint8((bits shr (8 * i)) and 255)

proc symmetric_drawing_cyclic_wedge*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.exportc, cdecl, dynlib.} =
  if input == nil or int(inputLength) < 3 or int(inputLength) > MaxInput: return -1
  let values = toOpenArray(input, 0, int(inputLength) - 1)
  let graphOpt = parse(values)
  if graphOpt.isNone: return -1
  let wordsOpt = solve(graphOpt.get)
  if wordsOpt.isNone: return -1
  let words = wordsOpt.get
  let required = words.len * 8
  if required > MaxOutput: return -1
  if output == nil or capacity < csize_t(required): return -2
  var temporary: array[MaxOutput, uint8]
  for i, word in words: writeI64Le(addr temporary[0], i * 8, word)
  for i in 0 ..< required: output[i] = temporary[i]
  int64(required)
