const MaxVertices = 16
const MaxEdges = 64
const MaxParseableInputLength = 2 + 3 * MaxEdges + 1
const MaxOutputWords = 1 + 2 * (MaxVertices - 1)
const MaxOutputBytes = 4 * MaxOutputWords
const SourceHeapSentinel = high(int64)

type
  I32Input = ptr UncheckedArray[int32]
  U8Output = ptr UncheckedArray[uint8]

proc topToBottom(heap: var array[MaxVertices, int64],
    positions: var array[MaxVertices, int32],
    nodePosition: var array[MaxVertices, int32], size, start: int) =
  var root = start
  while root * 2 + 1 < size:
    let left = root * 2 + 1
    let right = left + 1
    let child = if right >= size or heap[left] < heap[right]: left else: right
    if heap[child] >= heap[root]:
      break
    swap(heap[root], heap[child])
    swap(positions[root], positions[child])
    nodePosition[int(positions[root])] = int32(root)
    nodePosition[int(positions[child])] = int32(child)
    root = child

proc decreaseKey(value: int64, indexStart: int,
    heap: var array[MaxVertices, int64],
    positions: var array[MaxVertices, int32],
    nodePosition: var array[MaxVertices, int32]) =
  var index = indexStart
  let vertex = positions[index]
  while index != 0:
    let parent = (index - 1) div 2
    if value < heap[parent]:
      heap[index] = heap[parent]
      positions[index] = positions[parent]
      nodePosition[int(positions[parent])] = int32(index)
    else:
      heap[index] = value
      positions[index] = vertex
      nodePosition[int(vertex)] = int32(index)
      return
    index = parent
  heap[0] = value
  positions[0] = vertex
  nodePosition[int(vertex)] = 0

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0..<4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc minimum_spanning_tree_prims*(input: I32Input, length: csize_t,
    output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "minimum_spanning_tree_prims".} =
  if input == nil or length < 2 or length > csize_t(MaxParseableInputLength):
    return -1
  let rawVertices = input[0]
  let rawEdges = input[1]
  if rawVertices < 1 or rawVertices > MaxVertices.int32 or
      rawEdges < 0 or rawEdges > MaxEdges.int32:
    return -1
  let vertexCount = int(rawVertices)
  let edgeCount = int(rawEdges)
  if int(length) != 2 + 3 * edgeCount:
    return -1

  var neighbors: array[MaxVertices * MaxVertices, int32]
  var weights: array[MaxVertices * MaxVertices, int32]
  var degree: array[MaxVertices, int]
  var seen: array[MaxVertices * MaxVertices, bool]
  var position = 2
  for _ in 0..<edgeCount:
    let u = input[position]
    let v = input[position + 1]
    let weight = input[position + 2]
    position += 3
    if u < 0 or v <= u or v >= rawVertices:
      return -1
    let edgeIndex = int(u) * MaxVertices + int(v)
    if seen[edgeIndex]:
      return -1
    seen[edgeIndex] = true
    let uDegree = degree[int(u)]
    neighbors[int(u) * MaxVertices + uDegree] = v
    weights[int(u) * MaxVertices + uDegree] = weight
    degree[int(u)] += 1
    let vDegree = degree[int(v)]
    neighbors[int(v) * MaxVertices + vDegree] = u
    weights[int(v) * MaxVertices + vDegree] = weight
    degree[int(v)] += 1

  if vertexCount > 1:
    var reachedVertex: array[MaxVertices, bool]
    var stack: array[MaxVertices, int]
    var stackSize = 1
    var reached = 0
    stack[0] = 0
    reachedVertex[0] = true
    while stackSize > 0:
      dec stackSize
      let vertex = stack[stackSize]
      inc reached
      for i in 0..<degree[vertex]:
        let neighbor = int(neighbors[vertex * MaxVertices + i])
        if not reachedVertex[neighbor]:
          reachedVertex[neighbor] = true
          stack[stackSize] = neighbor
          inc stackSize
    if reached != vertexCount:
      return -1

  var visited: array[MaxVertices, bool]
  var parent: array[MaxVertices, int32]
  var heap: array[MaxVertices, int64]
  var positions: array[MaxVertices, int32]
  var nodePosition: array[MaxVertices, int32]
  for vertex in 0..<vertexCount:
    parent[vertex] = -1
    heap[vertex] = SourceHeapSentinel
    positions[vertex] = int32(vertex)
    nodePosition[vertex] = int32(vertex)
  visited[0] = true
  for i in 0..<degree[0]:
    let neighbor = int(neighbors[i])
    parent[neighbor] = 0
    heap[neighbor] = int64(weights[i])
  var start = vertexCount div 2
  while start > 0:
    dec start
    topToBottom(heap, positions, nodePosition, vertexCount, start)

  var words: array[MaxOutputWords, int32]
  var wordCount = 1
  var treeEdgeCount = 0
  for _step in 1..<vertexCount:
    let vertex = int(positions[0])
    heap[0] = SourceHeapSentinel
    topToBottom(heap, positions, nodePosition, vertexCount, 0)
    if not visited[vertex]:
      words[wordCount] = parent[vertex]
      words[wordCount + 1] = int32(vertex)
      wordCount += 2
      inc treeEdgeCount
      visited[vertex] = true
      for i in 0..<degree[vertex]:
        let neighbor = int(neighbors[vertex * MaxVertices + i])
        let weight = weights[vertex * MaxVertices + i]
        if not visited[neighbor]:
          let heapIndex = int(nodePosition[neighbor])
          if int64(weight) < heap[heapIndex]:
            heap[heapIndex] = int64(weight)
            decreaseKey(int64(weight), heapIndex, heap, positions, nodePosition)
            parent[neighbor] = int32(vertex)
  if treeEdgeCount != vertexCount - 1:
    return -1
  words[0] = int32(treeEdgeCount)
  let byteCount = wordCount * 4
  if byteCount > MaxOutputBytes or output == nil or capacity < csize_t(byteCount):
    return -2
  var buffer: array[MaxOutputBytes, uint8]
  for i in 0..<wordCount:
    putI32Le(cast[U8Output](addr buffer[0]), i * 4, words[i])
  for i in 0..<byteCount:
    output[i] = buffer[i]
  int64(byteCount)
