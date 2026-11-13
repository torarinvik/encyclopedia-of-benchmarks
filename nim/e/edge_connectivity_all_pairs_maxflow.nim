const
  MaxVertices = 10
  MaxEdges = 45
  MaxParseable = 93

proc pairFlow(adjacency: array[MaxVertices * MaxVertices, int], n, source, sink, limit: int): int =
  var residual = adjacency
  var flow = 0
  while flow < limit:
    var parent: array[MaxVertices, int]
    for v in 0 ..< n: parent[v] = -1
    var queue: array[MaxVertices, int]
    parent[source] = source
    var head = 0
    var tail = 0
    queue[tail] = source
    inc tail
    while head < tail and parent[sink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< n:
        if parent[v] < 0 and residual[u * MaxVertices + v] > 0:
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == sink: break
    if parent[sink] < 0: break
    var amount = limit - flow
    var v = sink
    while v != source:
      let u = parent[v]
      amount = min(amount, residual[u * MaxVertices + v])
      v = u
    v = sink
    while v != source:
      let u = parent[v]
      residual[u * MaxVertices + v] -= amount
      residual[v * MaxVertices + u] += amount
      v = u
    flow += amount
  flow

proc edge_connectivity_all_pairs_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "edge_connectivity_all_pairs_maxflow".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseable): return -1
  if input[0] < 2 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEdges: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 2 * m: return -1

  var adjacency: array[MaxVertices * MaxVertices, int]
  for e in 0 ..< m:
    let left = input[2 + 2 * e]
    let right = input[3 + 2 * e]
    if left < 0 or right < 0 or left >= int64(n) or right >= int64(n) or left == right: return -1
    let u = int(left)
    let v = int(right)
    if adjacency[u * MaxVertices + v] != 0: return -1
    adjacency[u * MaxVertices + v] = 1
    adjacency[v * MaxVertices + u] = 1

  var best = n - 1
  for source in 0 ..< n:
    for sink in (source + 1) ..< n:
      let flow = pairFlow(adjacency, n, source, sink, best)
      if flow < best: best = flow
      if best == 0: return 0
  int64(best)
