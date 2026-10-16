## BFS two-coloring for a bounded undirected graph.
proc is_graph_bipartite*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_graph_bipartite".} =
  const maxVertices = 64
  const maxEdges = 256
  const maxInputLength = 2 + 2 * maxEdges
  if values == nil or length < 2 or length > csize_t(maxInputLength): return -1
  let vertexCountRaw = values[0]
  let edgeCountRaw = values[1]
  if vertexCountRaw < 0 or vertexCountRaw > maxVertices or edgeCountRaw < 0 or edgeCountRaw > maxEdges:
    return -1
  let vertexCount = int(vertexCountRaw)
  let edgeCount = int(edgeCountRaw)
  if length != csize_t(2 + 2 * edgeCount): return -1

  var head: array[maxVertices, int]
  var arcTo: array[2 * maxEdges, int]
  var arcNext: array[2 * maxEdges, int]
  var side: array[maxVertices, int]
  var queue: array[maxVertices, int]
  for vertex in 0 ..< vertexCount:
    head[vertex] = -1
    side[vertex] = -1
  var arcCount = 0
  for edge in 0 ..< edgeCount:
    let uRaw = values[2 + 2 * edge]
    let vRaw = values[3 + 2 * edge]
    if uRaw < 1 or uRaw > vertexCountRaw or vRaw < 1 or vRaw > vertexCountRaw:
      return -1
    let u = int(uRaw - 1)
    let v = int(vRaw - 1)
    arcTo[arcCount] = v
    arcNext[arcCount] = head[u]
    head[u] = arcCount
    inc arcCount
    arcTo[arcCount] = u
    arcNext[arcCount] = head[v]
    head[v] = arcCount
    inc arcCount

  var bipartite = true
  for start in 0 ..< vertexCount:
    if side[start] != -1: continue
    var queueHead = 0
    var queueTail = 1
    queue[0] = start
    side[start] = 0
    while queueHead < queueTail:
      let current = queue[queueHead]
      inc queueHead
      var arc = head[current]
      while arc != -1:
        let neighbor = arcTo[arc]
        if side[neighbor] == -1:
          side[neighbor] = side[current] xor 1
          queue[queueTail] = neighbor
          inc queueTail
        elif side[neighbor] == side[current]:
          bipartite = false
        arc = arcNext[arc]
  if bipartite: 1 else: 0
