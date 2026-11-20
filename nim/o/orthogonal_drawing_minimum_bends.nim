const
  MaxN = 8
  MaxM = 16
  MaxF = 10
  MaxInput = 79
  MaxNodes = 20
  MaxEdges = 200
  Inf = 1'i64 shl 60

type FlowEdge = object
  fromNode: int
  toNode: int
  reverseIndex: int
  capacity: int64
  cost: int64

proc bendConnected(adjacency: array[MaxN, array[MaxN, bool]], n, removed: int): bool =
  let start = if removed == 0: 1 else: 0
  var seen: array[MaxN, bool]
  var stack: array[MaxN, int]
  var top = 1
  var count = 0
  seen[start] = true
  stack[0] = start
  while top > 0:
    dec top
    let u = stack[top]
    inc count
    for v in 0 ..< n:
      if v != removed and adjacency[u][v] and not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  count == n - (if removed >= 0: 1 else: 0)

proc addBendArc(edges: var array[MaxEdges, FlowEdge], count: var int,
                u, v: int, capacity, cost: int64): bool =
  if count + 2 > MaxEdges: return false
  let e = count
  edges[e] = FlowEdge(fromNode: u, toNode: v, reverseIndex: e + 1, capacity: capacity, cost: cost)
  edges[e + 1] = FlowEdge(fromNode: v, toNode: u, reverseIndex: e, capacity: 0, cost: -cost)
  count += 2
  true

proc orthogonal_drawing_minimum_bends*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "orthogonal_drawing_minimum_bends".} =
  if input.isNil or inputLength < 4 or inputLength > MaxInput.csize_t: return -1
  let n64 = input[0]
  let m64 = input[1]
  let f64 = input[2]
  let outer64 = input[3]
  if n64 < 3 or n64 > MaxN or m64 < n64 or m64 > MaxM or f64 < 2 or f64 > MaxF or
      f64 != m64 - n64 + 2 or outer64 < 0 or outer64 >= f64: return -1
  let n = int(n64)
  let m = int(m64)
  let f = int(f64)
  let outer = int(outer64)
  var adjacency: array[MaxN, array[MaxN, bool]]
  var degree: array[MaxN, int]
  var edgeU, edgeV: array[MaxM, int]
  var uses: array[MaxN, array[MaxN, int]]
  var cursor = 4
  for e in 0 ..< m:
    if cursor + 2 > int(inputLength): return -1
    let u64 = input[cursor]
    let v64 = input[cursor + 1]
    cursor += 2
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacency[u][v] or (e > 0 and (u < edgeU[e - 1] or (u == edgeU[e - 1] and v <= edgeV[e - 1]))): return -1
    adjacency[u][v] = true
    adjacency[v][u] = true
    inc degree[u]
    inc degree[v]
    edgeU[e] = u
    edgeV[e] = v
  for v in 0 ..< n:
    if degree[v] < 2 or degree[v] > 4: return -1

  var faces: array[MaxF, array[MaxN, int]]
  var widths: array[MaxF, int]
  var linkAdj: array[MaxN * MaxN * MaxN, bool]
  var linkDegree: array[MaxN * MaxN, int]
  for face in 0 ..< f:
    if cursor >= int(inputLength): return -1
    let width64 = input[cursor]
    inc cursor
    if width64 < 3 or width64 > n64 or cursor + int(width64) > int(inputLength): return -1
    let width = int(width64)
    widths[face] = width
    var rowSeen: array[MaxN, bool]
    for i in 0 ..< width:
      let vertex64 = input[cursor]
      inc cursor
      if vertex64 < 0 or vertex64 >= n64: return -1
      let vertex = int(vertex64)
      if rowSeen[vertex]: return -1
      rowSeen[vertex] = true
      faces[face][i] = vertex
    for i in 0 ..< width:
      let u = faces[face][i]
      let v = faces[face][(i + 1) mod width]
      if not adjacency[u][v]: return -1
      inc uses[u][v]
    for i in 0 ..< width:
      let center = faces[face][i]
      let before = faces[face][(i + width - 1) mod width]
      let after = faces[face][(i + 1) mod width]
      if before == after: return -1
      linkAdj[center * MaxN * MaxN + before * MaxN + after] = true
      linkAdj[center * MaxN * MaxN + after * MaxN + before] = true
      inc linkDegree[center * MaxN + before]
      inc linkDegree[center * MaxN + after]
  if cursor != int(inputLength) or n - m + f != 2 or not bendConnected(adjacency, n, -1): return -1
  for v in 0 ..< n:
    if not bendConnected(adjacency, n, v): return -1
  for e in 0 ..< m:
    if uses[edgeU[e]][edgeV[e]] != 1 or uses[edgeV[e]][edgeU[e]] != 1: return -1
  for center in 0 ..< n:
    var start = -1
    var incidentCount = 0
    for neighbor in 0 ..< n:
      if adjacency[center][neighbor]:
        if linkDegree[center * MaxN + neighbor] != 2: return -1
        if start < 0: start = neighbor
        inc incidentCount
      elif linkDegree[center * MaxN + neighbor] != 0: return -1
    var seen: array[MaxN, bool]
    var stack: array[MaxN, int]
    var top = 1
    var reached = 0
    seen[start] = true
    stack[0] = start
    while top > 0:
      dec top
      let neighbor = stack[top]
      inc reached
      for other in 0 ..< n:
        if linkAdj[center * MaxN * MaxN + neighbor * MaxN + other] and not seen[other]:
          seen[other] = true
          stack[top] = other
          inc top
    if reached != incidentCount: return -1
  var faceA, faceB, faceUse: array[MaxM, int]
  for face in 0 ..< f:
    for i in 0 ..< widths[face]:
      let u = faces[face][i]
      let v = faces[face][(i + 1) mod widths[face]]
      let lo = min(u, v)
      let hi = max(u, v)
      var found = -1
      for e in 0 ..< m:
        if edgeU[e] == lo and edgeV[e] == hi:
          found = e
          break
      if found < 0 or faceUse[found] >= 2: return -1
      if faceUse[found] == 0: faceA[found] = face
      else: faceB[found] = face
      inc faceUse[found]
  for e in 0 ..< m:
    if faceUse[e] != 2 or faceA[e] == faceB[e]: return -1
  if output.isNil or outputCapacity < 8: return -2

  let base = n + f
  let source = base
  let sink = base + 1
  let nodeCount = base + 2
  var edges: array[MaxEdges, FlowEdge]
  var edgeCount = 0
  var balance: array[MaxN + MaxF, int64]
  for v in 0 ..< n: balance[v] = 4
  for face in 0 ..< f:
    let d = int64(widths[face])
    balance[n + face] -= 2 * d + (if face == outer: 4 else: -4)
    for i in 0 ..< widths[face]:
      let v = faces[face][i]
      dec balance[v]
      inc balance[n + face]
      if not addBendArc(edges, edgeCount, v, n + face, int64(4 * n), 0): return -1
  for e in 0 ..< m:
    if not addBendArc(edges, edgeCount, n + faceA[e], n + faceB[e], int64(4 * n), 1) or
        not addBendArc(edges, edgeCount, n + faceB[e], n + faceA[e], int64(4 * n), 1): return -1
  var required = 0'i64
  for v in 0 ..< base:
    if balance[v] > 0:
      if not addBendArc(edges, edgeCount, source, v, balance[v], 0): return -1
      required += balance[v]
    elif balance[v] < 0 and not addBendArc(edges, edgeCount, v, sink, -balance[v], 0): return -1
  var potential: array[MaxNodes, int64]
  var totalFlow = 0'i64
  var totalCost = 0'i64
  while totalFlow < required:
    var distance: array[MaxNodes, int64]
    var parent: array[MaxNodes, int]
    var used: array[MaxNodes, bool]
    for v in 0 ..< nodeCount:
      distance[v] = Inf
      parent[v] = -1
    distance[source] = 0
    for _ in 0 ..< nodeCount:
      var chosen = -1
      for v in 0 ..< nodeCount:
        if not used[v] and distance[v] != Inf and (chosen < 0 or distance[v] < distance[chosen]): chosen = v
      if chosen < 0: break
      used[chosen] = true
      for e in 0 ..< edgeCount:
        if edges[e].fromNode != chosen or edges[e].capacity <= 0: continue
        let v = edges[e].toNode
        let candidate = distance[chosen] + edges[e].cost + potential[chosen] - potential[v]
        if not used[v] and candidate < distance[v]:
          distance[v] = candidate
          parent[v] = e
    if distance[sink] == Inf: return -1
    for v in 0 ..< nodeCount:
      if distance[v] != Inf: potential[v] += distance[v]
    var amount = required - totalFlow
    var pathCost = 0'i64
    var vertex = sink
    while vertex != source:
      let e = parent[vertex]
      if e < 0: return -1
      amount = min(amount, edges[e].capacity)
      pathCost += edges[e].cost
      vertex = edges[e].fromNode
    vertex = sink
    while vertex != source:
      let e = parent[vertex]
      edges[e].capacity -= amount
      edges[edges[e].reverseIndex].capacity += amount
      vertex = edges[e].fromNode
    totalFlow += amount
    totalCost += amount * pathCost
  let bits = uint64(totalCost)
  for i in 0 ..< 8: output[i] = uint8(bits shr (8 * i))
  8
