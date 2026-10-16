import core:c

const
  MaxVertices = 32
  MaxEdges = 256
  MaxInputLength = 4 + 2 * MaxEdges
  MaxOutputValues = 1 + MaxVertices

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc putI64(output: ByteOutput, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc breadth_first_search_shortest_path*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64 {.cdecl, exportc: "breadth_first_search_shortest_path".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  let startValue = input[2]
  let goalValue = input[3]
  if vertexValue < 1 or vertexValue > int64(MaxVertices) or edgeValue < 0 or edgeValue > int64(MaxEdges): return -1
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  if length != csize_t(4 + 2 * edges) or startValue < 0 or startValue >= int64(vertices) or goalValue < 0 or goalValue >= int64(vertices): return -1
  var adjacency: array[MaxVertices * MaxEdges, int]
  var degree: array[MaxVertices, int]
  for edge in 0 ..< edges:
    let fromValue = input[4 + 2 * edge]
    let toValue = input[5 + 2 * edge]
    if fromValue < 0 or fromValue >= int64(vertices) or toValue < 0 or toValue >= int64(vertices): return -1
    let source = int(fromValue)
    adjacency[source * MaxEdges + degree[source]] = int(toValue)
    inc degree[source]
  let start = int(startValue)
  let goal = int(goalValue)
  var parent: array[MaxVertices, int64]
  var visited: array[MaxVertices, bool]
  var queue: array[MaxVertices, int]
  for vertex in 0 ..< vertices: parent[vertex] = -1
  var head = 0
  var tail = 0
  visited[start] = true
  queue[tail] = start
  inc tail
  while head < tail and not visited[goal]:
    let node = queue[head]
    inc head
    for index in 0 ..< degree[node]:
      let neighbor = adjacency[node * MaxEdges + index]
      if visited[neighbor]: continue
      visited[neighbor] = true
      parent[neighbor] = int64(node)
      queue[tail] = neighbor
      inc tail
      if neighbor == goal: break
  var encoded: array[MaxOutputValues, int64]
  var pathCount = 0
  if visited[goal]:
    var reversePath: array[MaxVertices, int]
    var current = goal
    while current >= 0:
      reversePath[pathCount] = current
      inc pathCount
      if current == start: break
      current = int(parent[current])
    for index in 0 ..< pathCount: encoded[1 + index] = int64(reversePath[pathCount - 1 - index])
  encoded[0] = int64(pathCount)
  let required = (pathCount + 1) * 8
  if output.isNil or capacity < csize_t(required): return -2
  for index in 0 .. pathCount: putI64(output, index * 8, encoded[index])
  int64(required)
