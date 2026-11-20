const
  MinN = 3
  MaxN = 8
  MaxM = 12
  MaxLength = 39
  MaxCandidates = 96

type
  Edge = object
    u, v: int
    weight: int64

proc cycleWeight(mask: uint64, edges: array[MaxM, Edge], m: int): int64 =
  for e in 0 ..< m:
    if ((mask shr e) and 1'u64) != 0: result += edges[e].weight

proc hortonWeight(n, m: int, edges: array[MaxM, Edge]): int64 =
  var candidates: array[MaxCandidates, uint64]
  var costs: array[MaxCandidates, int64]
  var candidateCount = 0
  for root in 0 ..< n:
    var distance: array[MaxN, int64]
    var parent, parentEdge: array[MaxN, int]
    var treeEdge: array[MaxM, bool]
    var vertexSettled: array[MaxN, bool]
    var pathMask: array[MaxN, uint64]
    for v in 0 ..< n:
      distance[v] = int64.high
      parent[v] = -1
      parentEdge[v] = -1
    distance[root] = 0
    let tieScale = int64(m + 1) * (1'i64 shl m)
    for step in 0 ..< n:
      var vertex = -1
      for v in 0 ..< n:
        if not vertexSettled[v] and distance[v] != int64.high and
            (vertex < 0 or distance[v] < distance[vertex] or (distance[v] == distance[vertex] and v < vertex)):
          vertex = v
      if vertex < 0: break
      vertexSettled[vertex] = true
      for e in 0 ..< m:
        let edge = edges[e]
        var neighbor = -1
        if edge.u == vertex: neighbor = edge.v
        elif edge.v == vertex: neighbor = edge.u
        if neighbor < 0 or vertexSettled[neighbor]: continue
        let candidate = distance[vertex] + edge.weight * tieScale + (1'i64 shl e)
        if candidate < distance[neighbor]:
          distance[neighbor] = candidate
          parent[neighbor] = vertex
          parentEdge[neighbor] = e
    for v in 0 ..< n:
      if v == root: continue
      var cursor = v
      var steps = 0
      while cursor != root and steps < n:
        let pe = parentEdge[cursor]
        if pe < 0: return -1
        treeEdge[pe] = true
        pathMask[v] = pathMask[v] or (1'u64 shl pe)
        cursor = parent[cursor]
        inc steps
      if cursor != root: return -1
    for e in 0 ..< m:
      if treeEdge[e]: continue
      let edge = edges[e]
      let cycle = pathMask[edge.u] xor pathMask[edge.v] xor (1'u64 shl e)
      if cycle == 0: continue
      var duplicate = false
      for i in 0 ..< candidateCount:
        if candidates[i] == cycle: duplicate = true; break
      if not duplicate and candidateCount < MaxCandidates:
        candidates[candidateCount] = cycle
        costs[candidateCount] = cycleWeight(cycle, edges, m)
        inc candidateCount
  for i in 0 ..< candidateCount:
    for j in i + 1 ..< candidateCount:
      if costs[j] < costs[i] or (costs[j] == costs[i] and candidates[j] < candidates[i]):
        swap(costs[i], costs[j])
        swap(candidates[i], candidates[j])
  let dimension = m - n + 1
  var basis: array[MaxM, uint64]
  var rank = 0
  var total = 0'i64
  for i in 0 ..< candidateCount:
    if rank == dimension: break
    var residual = candidates[i]
    for bit in countdown(m - 1, 0):
      if ((residual shr bit) and 1'u64) == 0: continue
      if basis[bit] != 0: residual = residual xor basis[bit]
      else:
        basis[bit] = residual
        inc rank
        total += costs[i]
        break
  if rank == dimension: total else: -1

proc minimum_cycle_basis_horton*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.exportc, dynlib.} =
  if input == nil or length < 2 or length > MaxLength: return -1
  if input[0] < MinN or input[0] > MaxN: return -1
  let n = int(input[0])
  if input[1] < int64(n - 1) or input[1] > MaxM or input[1] > int64(n * (n - 1) div 2): return -1
  let m = int(input[1])
  if int(length) != 2 + 3 * m: return -1
  var edges: array[MaxM, Edge]
  var adjacent: array[MaxN, array[MaxN, bool]]
  var previousU = -1
  var previousV = -1
  for e in 0 ..< m:
    let ru = input[2 + 3 * e]
    let rv = input[3 + 3 * e]
    let weight = input[4 + 3 * e]
    if ru < 0 or rv < 0 or ru >= int64(n) or rv >= int64(n) or ru >= rv or weight < 1 or weight > 9: return -1
    let u = int(ru)
    let v = int(rv)
    if e > 0 and (u < previousU or (u == previousU and v <= previousV)): return -1
    previousU = u
    previousV = v
    edges[e] = Edge(u: u, v: v, weight: weight)
    adjacent[u][v] = true
    adjacent[v][u] = true
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  seen[0] = true
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if adjacent[u][v] and not seen[v]:
        seen[v] = true
        queue[tail] = v
        inc tail
  for v in 0 ..< n:
    if not seen[v]: return -1
  hortonWeight(n, m, edges)
