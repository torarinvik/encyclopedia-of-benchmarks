const MaxVertices = 16
const MaxEdges = 16
const MaxInputLength = 52

type Edge = object
  u: int
  v: int
  weight: int64
  originalId: int

proc edgeLess(left, right: Edge): bool =
  left.weight < right.weight or
    (left.weight == right.weight and left.originalId < right.originalId)

proc findRoot(parent: var array[MaxVertices, int], start: int): int =
  var root = start
  while parent[root] != root:
    root = parent[root]
  var vertex = start
  while parent[vertex] != vertex:
    let next = parent[vertex]
    parent[vertex] = root
    vertex = next
  root

proc splitmix64Next(state: var uint64): uint64 =
  state = state +% 0x9E3779B97F4A7C15'u64
  var value = state
  value = (value xor (value shr 30)) *% 0xBF58476D1CE4E5B9'u64
  value = (value xor (value shr 27)) *% 0x94D049BB133111EB'u64
  value xor (value shr 31)

proc boruvkaPhase(vertexCount, edgeCount: var int,
    edges: var array[MaxEdges, Edge]): uint64 =
  var selected: array[MaxEdges, bool]
  for vertex in 0..<vertexCount:
    var best = -1
    for edgeIndex in 0..<edgeCount:
      let edge = edges[edgeIndex]
      if edge.u != vertex and edge.v != vertex: continue
      if best < 0 or edgeLess(edge, edges[best]): best = edgeIndex
    if best >= 0: selected[best] = true

  var parent: array[MaxVertices, int]
  for vertex in 0..<vertexCount: parent[vertex] = vertex
  var selectedMask = 0'u64
  for edgeIndex in 0..<edgeCount:
    if not selected[edgeIndex]: continue
    let edge = edges[edgeIndex]
    selectedMask = selectedMask or (1'u64 shl edge.originalId)
    let left = findRoot(parent, edge.u)
    let right = findRoot(parent, edge.v)
    if left != right: parent[right] = left

  var rootToNew: array[MaxVertices, int]
  for vertex in 0..<MaxVertices: rootToNew[vertex] = -1
  var remapped: array[MaxVertices, int]
  var newVertexCount = 0
  for vertex in 0..<vertexCount:
    let root = findRoot(parent, vertex)
    if rootToNew[root] < 0:
      rootToNew[root] = newVertexCount
      inc newVertexCount
    remapped[vertex] = rootToNew[root]

  var reduced: array[MaxEdges, Edge]
  var reducedCount = 0
  for edgeIndex in 0..<edgeCount:
    var edge = edges[edgeIndex]
    var left = remapped[edge.u]
    var right = remapped[edge.v]
    if left == right: continue
    if left > right: swap(left, right)
    edge.u = left
    edge.v = right
    var parallel = -1
    for prior in 0..<reducedCount:
      if reduced[prior].u == left and reduced[prior].v == right:
        parallel = prior
        break
    if parallel >= 0:
      if edgeLess(edge, reduced[parallel]): reduced[parallel] = edge
    else:
      reduced[reducedCount] = edge
      inc reducedCount

  vertexCount = newVertexCount
  edgeCount = reducedCount
  edges = reduced
  selectedMask

proc pathMaximum(edgeCount: int, edges: array[MaxEdges, Edge], forestMask: uint64,
    source, target: int, maxWeight, maxId: var int64): bool =
  var parentVertex: array[MaxVertices, int]
  var parentEdge: array[MaxVertices, int]
  for vertex in 0..<MaxVertices:
    parentVertex[vertex] = -1
    parentEdge[vertex] = -1
  var queue: array[MaxVertices, int]
  var head = 0
  var tail = 1
  queue[0] = source
  parentVertex[source] = source
  while head < tail and parentVertex[target] < 0:
    let current = queue[head]
    inc head
    for edgeIndex in 0..<edgeCount:
      let edge = edges[edgeIndex]
      if (forestMask and (1'u64 shl edge.originalId)) == 0'u64: continue
      var next = -1
      if edge.u == current: next = edge.v
      elif edge.v == current: next = edge.u
      if next >= 0 and parentVertex[next] < 0:
        parentVertex[next] = current
        parentEdge[next] = edgeIndex
        queue[tail] = next
        inc tail
  if parentVertex[target] < 0: return false

  maxWeight = -1
  maxId = -1
  var current = target
  while current != source:
    let edge = edges[parentEdge[current]]
    if edge.weight > maxWeight or
        (edge.weight == maxWeight and int64(edge.originalId) > maxId):
      maxWeight = edge.weight
      maxId = int64(edge.originalId)
    current = parentVertex[current]
  true

proc recursiveMst(initialVertexCount, initialEdgeCount: int,
    initialEdges: array[MaxEdges, Edge], state: var uint64): uint64 =
  if initialEdgeCount == 0: return 0'u64
  var vertexCount = initialVertexCount
  var edgeCount = initialEdgeCount
  var edges = initialEdges
  var selectedMask = 0'u64
  for _ in 0..<2:
    selectedMask = selectedMask or boruvkaPhase(vertexCount, edgeCount, edges)
    if edgeCount == 0: return selectedMask

  for index in 1..<edgeCount:
    let edge = edges[index]
    var position = index
    while position > 0 and edgeLess(edge, edges[position - 1]):
      edges[position] = edges[position - 1]
      dec position
    edges[position] = edge

  var sampleEdges: array[MaxEdges, Edge]
  var sampleCount = 0
  for edgeIndex in 0..<edgeCount:
    if (splitmix64Next(state) and 1'u64) != 0'u64:
      sampleEdges[sampleCount] = edges[edgeIndex]
      inc sampleCount
  let forestMask = recursiveMst(vertexCount, sampleCount, sampleEdges, state)

  var lightEdges: array[MaxEdges, Edge]
  var lightCount = 0
  for edgeIndex in 0..<edgeCount:
    let edge = edges[edgeIndex]
    let inForest = (forestMask and (1'u64 shl edge.originalId)) != 0'u64
    var heavy = false
    if not inForest:
      var maxWeight, maxId: int64
      if pathMaximum(edgeCount, edges, forestMask, edge.u, edge.v, maxWeight, maxId):
        heavy = edge.weight > maxWeight or
          (edge.weight == maxWeight and int64(edge.originalId) > maxId)
    if not heavy:
      lightEdges[lightCount] = edge
      inc lightCount

  selectedMask or recursiveMst(vertexCount, lightCount, lightEdges, state)

proc kkt_recursive_mst*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kkt_recursive_mst".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInputLength): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  let seedValue = input[2]
  if vertexValue < 1'i64 or vertexValue > int64(MaxVertices) or
      edgeValue < 0'i64 or edgeValue > int64(MaxEdges) or seedValue < 0'i64: return -1
  let vertexCount = int(vertexValue)
  let edgeCount = int(edgeValue)
  if length != csize_t(3 + 3 * edgeCount): return -1

  var edges: array[MaxEdges, Edge]
  for edgeIndex in 0..<edgeCount:
    let uValue = input[3 + 3 * edgeIndex]
    let vValue = input[4 + 3 * edgeIndex]
    let weight = input[5 + 3 * edgeIndex]
    if uValue < 0'i64 or vValue <= uValue or vValue >= vertexValue or
        weight < 0'i64 or weight > 255'i64: return -1
    let u = int(uValue)
    let v = int(vValue)
    for prior in 0..<edgeIndex:
      if edges[prior].u == u and edges[prior].v == v: return -1
    edges[edgeIndex] = Edge(u: u, v: v, weight: weight, originalId: edgeIndex)

  var state = uint64(seedValue)
  int64(recursiveMst(vertexCount, edgeCount, edges, state))
