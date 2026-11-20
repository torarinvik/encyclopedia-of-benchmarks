import std/options

const
  MaxN = 8
  MaxM = 18
  MaxF = 12
  MaxInput = 55

type Graph = object
  n, c, m, f, outerU, outerV, outerFace: int
  degree, mask: array[MaxN, int]
  edgeU, edgeV: array[MaxM, int]
  rotation, faceOf: array[MaxN, array[MaxN, int]]
  adjacent: array[MaxN, array[MaxN, bool]]

proc root(parent: var array[MaxF, int], x0: int): int =
  var x = x0
  while parent[x] != x:
    parent[x] = parent[parent[x]]
    x = parent[x]
  x

proc connected(g: Graph, mask: int): bool =
  var start = -1
  var expected = 0
  for v in 0 ..< g.n:
    if ((mask shr v) and 1) != 0:
      if start < 0: start = v
      inc expected
  if expected <= 1: return true
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  queue[0] = start
  seen[start] = true
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< g.n:
      if ((mask shr v) and 1) != 0 and g.adjacent[u][v] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  tail == expected

proc parse(input: ptr UncheckedArray[int64], length: int): Option[Graph] =
  if input.isNil or length < 4 or length > MaxInput: return none(Graph)
  if input[0] < 3 or input[0] > MaxN or input[1] < 0 or input[1] > input[0] - 2:
    return none(Graph)
  var g: Graph
  g.n = int(input[0]); g.c = int(input[1])
  if input[2] < 0 or input[2] >= input[0] or input[3] < 0 or input[3] >= input[0] or input[2] == input[3]:
    return none(Graph)
  g.outerU = int(input[2]); g.outerV = int(input[3])
  var offset = 4
  var degreeSum = 0
  for u in 0 ..< g.n:
    if offset >= length: return none(Graph)
    let dRaw = input[offset]
    inc offset
    if dRaw < 1 or dRaw >= input[0] or offset + int(dRaw) > length: return none(Graph)
    let d = int(dRaw)
    g.degree[u] = d
    degreeSum += d
    var rowSeen: array[MaxN, bool]
    for i in 0 ..< d:
      let raw = input[offset]
      inc offset
      if raw < 0 or raw >= input[0] or raw == int64(u): return none(Graph)
      let v = int(raw)
      if rowSeen[v]: return none(Graph)
      rowSeen[v] = true
      g.rotation[u][i] = v
      g.adjacent[u][v] = true
  if degreeSum mod 2 != 0 or offset + g.c != length: return none(Graph)
  g.m = degreeSum div 2
  if g.m < g.n - 1 or g.m > MaxM or not g.adjacent[g.outerU][g.outerV]: return none(Graph)
  var edgeCount = 0
  for u in 0 ..< g.n:
    for v in 0 ..< g.n:
      if g.adjacent[u][v] != g.adjacent[v][u]: return none(Graph)
      if u < v and g.adjacent[u][v]:
        g.edgeU[edgeCount] = u
        g.edgeV[edgeCount] = v
        inc edgeCount
  if edgeCount != g.m: return none(Graph)
  let full = (1 shl g.n) - 1
  for i in 0 ..< g.c:
    let raw = input[offset + i]
    if raw <= 0 or raw >= int64(full): return none(Graph)
    let mask = int(raw)
    var bits = 0
    for v in 0 ..< g.n: bits += (mask shr v) and 1
    if bits < 2: return none(Graph)
    for j in 0 ..< i:
      if g.mask[j] == mask: return none(Graph)
      let overlap = g.mask[j] and mask
      if overlap != 0 and overlap != g.mask[j] and overlap != mask: return none(Graph)
    g.mask[i] = mask
    if not connected(g, mask): return none(Graph)
  if not connected(g, full): return none(Graph)
  for u in 0 ..< MaxN:
    for v in 0 ..< MaxN: g.faceOf[u][v] = -1
  g.f = 0
  for e in 0 ..< g.m:
    for side in 0 ..< 2:
      let su = if side == 0: g.edgeU[e] else: g.edgeV[e]
      let sv = if side == 0: g.edgeV[e] else: g.edgeU[e]
      if g.faceOf[su][sv] >= 0: continue
      if g.f >= MaxF: return none(Graph)
      var local: array[MaxN, array[MaxN, bool]]
      var u = su
      var v = sv
      var steps = 0
      while true:
        if local[u][v] or g.faceOf[u][v] >= 0: return none(Graph)
        local[u][v] = true
        g.faceOf[u][v] = g.f
        var at = -1
        for i in 0 ..< g.degree[v]:
          if g.rotation[v][i] == u: at = i
        if at < 0: return none(Graph)
        let next = g.rotation[v][(at + 1) mod g.degree[v]]
        u = v; v = next
        if u == su and v == sv: break
        inc steps
        if steps > 2 * g.m: return none(Graph)
      inc g.f
  if g.f != g.m - g.n + 2: return none(Graph)
  for u in 0 ..< g.n:
    for v in 0 ..< g.n:
      if g.adjacent[u][v] and g.faceOf[u][v] < 0: return none(Graph)
  g.outerFace = g.faceOf[g.outerU][g.outerV]
  if g.outerFace < 0: return none(Graph)
  some(g)

proc c_connected_clustered_embedding_condition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "c_connected_clustered_embedding_condition".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let parsed = parse(input, int(length))
  if parsed.isNone: return -1
  let g = parsed.get
  for ci in 0 ..< g.c:
    var parent: array[MaxF, int]
    for f in 0 ..< g.f: parent[f] = f
    let mask = g.mask[ci]
    for e in 0 ..< g.m:
      let u = g.edgeU[e]; let v = g.edgeV[e]
      if ((mask shr u) and 1) != 0 and ((mask shr v) and 1) != 0: continue
      let a = root(parent, g.faceOf[u][v])
      let b = root(parent, g.faceOf[v][u])
      parent[a] = b
    let outside = root(parent, g.outerFace)
    for v in 0 ..< g.n:
      if ((mask shr v) and 1) != 0: continue
      var incident = false
      for u in 0 ..< g.n:
        if g.adjacent[v][u]:
          incident = true
          if root(parent, g.faceOf[v][u]) != outside: return 0
      if not incident: return -1
    for e in 0 ..< g.m:
      let u = g.edgeU[e]; let v = g.edgeV[e]
      if ((mask shr u) and 1) != 0 and ((mask shr v) and 1) != 0: continue
      if root(parent, g.faceOf[u][v]) != outside: return 0
  1
