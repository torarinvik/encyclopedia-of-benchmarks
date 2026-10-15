const
  MaxVertexCount = 64
  MaxEdgeCount = 2047
  MaxInputLength = 2 + 2 * MaxEdgeCount

proc visitVertex(adjacency: var array[MaxVertexCount, uint64], vertexCount, vertex: int,
    discovery, low, parent: var array[MaxVertexCount, int64],
    isArticulation: var array[MaxVertexCount, bool], time: var int) =
  discovery[vertex] = int64(time)
  low[vertex] = int64(time)
  inc time
  var childCount = 0
  for neighbor in 0 ..< vertexCount:
    if (adjacency[vertex] and (1'u64 shl neighbor)) == 0'u64: continue
    if discovery[neighbor] == -1'i64:
      parent[neighbor] = int64(vertex)
      inc childCount
      visitVertex(adjacency, vertexCount, neighbor, discovery, low, parent, isArticulation, time)
      if low[neighbor] < low[vertex]: low[vertex] = low[neighbor]
      if parent[vertex] == -1'i64 and childCount > 1: isArticulation[vertex] = true
      if parent[vertex] != -1'i64 and low[neighbor] >= discovery[vertex]: isArticulation[vertex] = true
    elif int64(neighbor) != parent[vertex] and discovery[neighbor] < low[vertex]:
      low[vertex] = discovery[neighbor]

proc articulation_points*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "articulation_points".} =
  if input.isNil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 0'i64 or input[0] > MaxVertexCount or input[1] < 0'i64 or input[1] > MaxEdgeCount:
    return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 2 * edgeCount: return -1
  var adjacency: array[MaxVertexCount, uint64]
  for edge in 0 ..< edgeCount:
    let leftValue = input[2 + 2 * edge]
    let rightValue = input[3 + 2 * edge]
    if leftValue < 0'i64 or rightValue < 0'i64 or leftValue >= int64(vertexCount) or
        rightValue >= int64(vertexCount): return -1
    let left = int(leftValue)
    let right = int(rightValue)
    adjacency[left] = adjacency[left] or (1'u64 shl right)
    adjacency[right] = adjacency[right] or (1'u64 shl left)

  var discovery: array[MaxVertexCount, int64]
  var low: array[MaxVertexCount, int64]
  var parent: array[MaxVertexCount, int64]
  var isArticulation: array[MaxVertexCount, bool]
  for vertex in 0 ..< vertexCount:
    discovery[vertex] = -1'i64
    parent[vertex] = -1'i64
  var time = 0
  for vertex in 0 ..< vertexCount:
    if discovery[vertex] == -1'i64:
      visitVertex(adjacency, vertexCount, vertex, discovery, low, parent, isArticulation, time)
  var pointCount = 0
  for vertex in 0 ..< vertexCount:
    if isArticulation[vertex]: inc pointCount
  if outputCapacity < csize_t(pointCount) or (pointCount != 0 and output.isNil): return -2
  var position = 0
  for vertex in 0 ..< vertexCount:
    if isArticulation[vertex]:
      output[position] = uint8(vertex)
      inc position
  int64(pointCount)
