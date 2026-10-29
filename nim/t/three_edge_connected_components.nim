const
  MaxVertices = 8
  MaxEdges = 32
  MaxInputLength = 2 + 2 * MaxEdges

type
  Edge = object
    u, v: int
  EdgeArray = array[MaxEdges, Edge]
  SameMatrix = array[MaxVertices * MaxVertices, bool]

proc refineForRemoval(edges: var EdgeArray, vertexCount, edgeCount, removedFirst, removedSecond: int,
                      same: var SameMatrix) =
  var component: array[MaxVertices, int]
  for vertex in 0 ..< vertexCount: component[vertex] = -1
  var queue: array[MaxVertices, int]
  var nextComponent = 0
  for start in 0 ..< vertexCount:
    if component[start] >= 0: continue
    var head = 0
    var tail = 0
    component[start] = nextComponent
    queue[tail] = start
    inc tail
    while head < tail:
      let vertex = queue[head]
      inc head
      for edgeId in 0 ..< edgeCount:
        if edgeId == removedFirst or edgeId == removedSecond: continue
        let edge = edges[edgeId]
        var neighbor = -1
        if edge.u == vertex: neighbor = edge.v
        elif edge.v == vertex: neighbor = edge.u
        if neighbor >= 0 and component[neighbor] < 0:
          component[neighbor] = nextComponent
          queue[tail] = neighbor
          inc tail
    inc nextComponent
  for first in 0 ..< vertexCount:
    for second in first + 1 ..< vertexCount:
      if component[first] != component[second]:
        same[first * MaxVertices + second] = false
        same[second * MaxVertices + first] = false

proc three_edge_connected_components*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "three_edge_connected_components".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if values[0] < 1 or values[0] > int64(MaxVertices)
      or values[1] < 0 or values[1] > int64(MaxEdges): return -1
  let vertexCount = int(values[0])
  let edgeCount = int(values[1])
  if length != csize_t(2 + 2 * edgeCount): return -1

  var edges: EdgeArray
  for edgeId in 0 ..< edgeCount:
    let fromValue = values[2 + 2 * edgeId]
    let toValue = values[3 + 2 * edgeId]
    if fromValue < 0 or fromValue >= int64(vertexCount)
        or toValue < 0 or toValue >= int64(vertexCount): return -1
    edges[edgeId] = Edge(u: int(fromValue), v: int(toValue))

  var same: SameMatrix
  for pair in 0 ..< same.len: same[pair] = true
  refineForRemoval(edges, vertexCount, edgeCount, -1, -1, same)
  for first in 0 ..< edgeCount:
    refineForRemoval(edges, vertexCount, edgeCount, first, -1, same)
    for second in first + 1 ..< edgeCount:
      refineForRemoval(edges, vertexCount, edgeCount, first, second, same)

  var labels: array[MaxVertices, int]
  for vertex in 0 ..< vertexCount: labels[vertex] = -1
  var nextLabel = 0
  for first in 0 ..< vertexCount:
    if labels[first] >= 0: continue
    for vertex in first ..< vertexCount:
      if labels[vertex] < 0 and same[first * MaxVertices + vertex]: labels[vertex] = nextLabel
    inc nextLabel
  var encoded = 0'i64
  var place = 1'i64
  for vertex in 0 ..< vertexCount:
    encoded += int64(labels[vertex]) * place
    place *= 8
  encoded
