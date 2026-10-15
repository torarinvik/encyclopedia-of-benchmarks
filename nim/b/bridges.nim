const
  MaxVertexCount = 64
  MaxEdgeCount = 2047
  MaxInputLength = 2 + 2 * MaxEdgeCount

proc visitVertex(adjacency: var array[MaxVertexCount, uint64],
    bridgeMask: var array[MaxVertexCount, uint64], vertexCount, vertex: int,
    discovery, low, parent: var array[MaxVertexCount, int64], time: var int) =
  discovery[vertex] = int64(time)
  low[vertex] = int64(time)
  inc time
  for neighbor in 0 ..< vertexCount:
    if (adjacency[vertex] and (1'u64 shl neighbor)) == 0'u64: continue
    if discovery[neighbor] == -1'i64:
      parent[neighbor] = int64(vertex)
      visitVertex(adjacency, bridgeMask, vertexCount, neighbor, discovery, low, parent, time)
      if low[neighbor] < low[vertex]: low[vertex] = low[neighbor]
      if low[neighbor] > discovery[vertex]:
        bridgeMask[vertex] = bridgeMask[vertex] or (1'u64 shl neighbor)
        bridgeMask[neighbor] = bridgeMask[neighbor] or (1'u64 shl vertex)
    elif int64(neighbor) != parent[vertex] and discovery[neighbor] < low[vertex]:
      low[vertex] = discovery[neighbor]

proc bridges*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bridges".} =
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

  var bridgeMask: array[MaxVertexCount, uint64]
  var discovery: array[MaxVertexCount, int64]
  var low: array[MaxVertexCount, int64]
  var parent: array[MaxVertexCount, int64]
  for vertex in 0 ..< vertexCount:
    discovery[vertex] = -1'i64
    parent[vertex] = -1'i64
  var time = 0
  for vertex in 0 ..< vertexCount:
    if discovery[vertex] == -1'i64:
      visitVertex(adjacency, bridgeMask, vertexCount, vertex, discovery, low, parent, time)
  var bridgeCount = 0
  for left in 0 ..< vertexCount:
    for right in (left + 1) ..< vertexCount:
      if (bridgeMask[left] and (1'u64 shl right)) != 0'u64: inc bridgeCount
  let outputLength = 2 * bridgeCount
  if outputCapacity < csize_t(outputLength) or (outputLength != 0 and output.isNil): return -2
  var position = 0
  for left in 0 ..< vertexCount:
    for right in (left + 1) ..< vertexCount:
      if (bridgeMask[left] and (1'u64 shl right)) != 0'u64:
        output[position] = uint8(left)
        output[position + 1] = uint8(right)
        position += 2
  int64(outputLength)
