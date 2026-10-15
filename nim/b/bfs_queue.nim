const MaxVertexCount = 64
const MaxEdgeCount = 2046
const MaxInputLength = 4 + 2 * MaxEdgeCount

proc bfs_queue*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bfs_queue".} =
  if input.isNil or length < 4 or length > MaxInputLength.csize_t: return -1
  if input[0] < 1'i64 or input[0] > MaxVertexCount or input[3] < 0'i64 or input[3] > MaxEdgeCount:
    return -1
  let vertexCount = int(input[0])
  let sourceArg = input[1]
  let targetArg = input[2]
  let edgeCount = int(input[3])
  if sourceArg < 0'i64 or sourceArg >= int64(vertexCount) or targetArg < 0'i64 or
      targetArg >= int64(vertexCount) or int(length) != 4 + 2 * edgeCount: return -1

  var adjacency: array[MaxVertexCount, uint64]
  for edge in 0 ..< edgeCount:
    let leftArg = input[4 + 2 * edge]
    let rightArg = input[5 + 2 * edge]
    if leftArg < 0'i64 or rightArg < 0'i64 or leftArg >= int64(vertexCount) or
        rightArg >= int64(vertexCount): return -1
    let left = int(leftArg)
    let right = int(rightArg)
    adjacency[left] = adjacency[left] or (1'u64 shl right)
    adjacency[right] = adjacency[right] or (1'u64 shl left)

  let source = int(sourceArg)
  let target = int(targetArg)
  var predecessor: array[MaxVertexCount, int]
  var visited: array[MaxVertexCount, bool]
  var queue: array[MaxVertexCount, int]
  for vertex in 0 ..< vertexCount: predecessor[vertex] = -1
  predecessor[source] = source
  visited[source] = true
  var head = 0
  var tail = 1
  queue[0] = source
  var found = source == target
  while head < tail and not found:
    let current = queue[head]
    inc head
    for neighbor in 0 ..< vertexCount:
      if (adjacency[current] and (1'u64 shl neighbor)) == 0 or visited[neighbor]: continue
      visited[neighbor] = true
      predecessor[neighbor] = current
      if neighbor == target:
        found = true
        break
      queue[tail] = neighbor
      inc tail
  if not found:
    if outputCapacity < 1 or output.isNil: return -2
    output[0] = 0'u8
    return 1

  var path: array[MaxVertexCount, uint8]
  var pathLength = 0
  var current = target
  while current != source:
    path[pathLength] = uint8(current)
    inc pathLength
    current = predecessor[current]
  path[pathLength] = uint8(source)
  inc pathLength
  if outputCapacity < csize_t(pathLength + 1) or output.isNil: return -2
  output[0] = 1'u8
  for index in 0 ..< pathLength: output[index + 1] = path[index]
  int64(pathLength + 1)
