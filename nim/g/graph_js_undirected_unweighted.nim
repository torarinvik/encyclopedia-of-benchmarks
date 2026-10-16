const MaxVertices = 26
const MaxEdges = 256
const MaxDegree = 512
const MaxInputLength = 541
const MaxOutputValues = 645
const MaxQueue = 513

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc graph_js_undirected_unweighted*(values: I64Input, length: csize_t,
    output: U8Output, outputCapacity: csize_t): int64 {.cdecl, exportc: "graph_js_undirected_unweighted".} =
  if values == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let rawVertexCount = values[0]
  if rawVertexCount < 1 or rawVertexCount > int64(MaxVertices): return -1
  let vertexCount = int(rawVertexCount)
  let count = int(length)
  if count < 1 + vertexCount + 2: return -1

  var vertices: array[MaxVertices, int]
  var declared: array[MaxVertices, bool]
  for index in 0 ..< vertexCount:
    let value = values[1 + index]
    if value < 97 or value > 122: return -1
    let vertex = int(value - 97)
    if declared[vertex]: return -1
    declared[vertex] = true
    vertices[index] = vertex

  let edgeCountOffset = 1 + vertexCount
  let rawEdgeCount = values[edgeCountOffset]
  if rawEdgeCount < 0 or rawEdgeCount > int64(MaxEdges): return -1
  let edgeCount = int(rawEdgeCount)
  if count != 1 + vertexCount + 1 + 2 * edgeCount + 1: return -1

  var adjacency: array[MaxVertices * MaxDegree, uint8]
  var degree: array[MaxVertices, int]
  var position = edgeCountOffset + 1
  for _ in 0 ..< edgeCount:
    let leftValue = values[position]
    let rightValue = values[position + 1]
    position += 2
    if leftValue < 97 or leftValue > 122 or rightValue < 97 or rightValue > 122: return -1
    let left = int(leftValue - 97)
    let right = int(rightValue - 97)
    if declared[left] and declared[right]:
      if degree[left] >= MaxDegree or degree[right] >= MaxDegree: return -1
      adjacency[left * MaxDegree + degree[left]] = uint8(right)
      inc degree[left]
      adjacency[right * MaxDegree + degree[right]] = uint8(left)
      inc degree[right]
  let startValue = values[position]
  if startValue < 97 or startValue > 122: return -1
  let start = int(startValue - 97)
  if not declared[start]: return -1

  var encodedValues: array[MaxOutputValues, int64]
  var resultLength = 0
  encodedValues[resultLength] = int64(vertexCount)
  inc resultLength
  for index in 0 ..< vertexCount:
    let vertex = vertices[index]
    encodedValues[resultLength] = int64(97 + vertex)
    encodedValues[resultLength + 1] = int64(degree[vertex])
    resultLength += 2
    for edge in 0 ..< degree[vertex]:
      encodedValues[resultLength] = int64(97 + int(adjacency[vertex * MaxDegree + edge]))
      inc resultLength

  var visited: array[MaxVertices, bool]
  var queue: array[MaxQueue, int]
  var levels: array[MaxQueue, int]
  let bfsCountSlot = resultLength
  inc resultLength
  var head = 0
  var tail = 0
  queue[tail] = start
  levels[tail] = 0
  inc tail
  var bfsCount = 0
  while head < tail:
    let vertex = queue[head]
    let level = levels[head]
    inc head
    if visited[vertex]: continue
    visited[vertex] = true
    encodedValues[resultLength] = int64(97 + vertex)
    encodedValues[resultLength + 1] = int64(level)
    resultLength += 2
    inc bfsCount
    for edge in 0 ..< degree[vertex]:
      queue[tail] = int(adjacency[vertex * MaxDegree + edge])
      levels[tail] = level + 1
      inc tail
  encodedValues[bfsCountSlot] = int64(bfsCount)

  for index in 0 ..< MaxVertices: visited[index] = false
  let dfsCountSlot = resultLength
  inc resultLength
  var stackVertices: array[MaxVertices, int]
  var stackNextEdge: array[MaxVertices, int]
  var stackDepth = 1
  stackVertices[0] = start
  visited[start] = true
  encodedValues[resultLength] = int64(97 + start)
  inc resultLength
  var dfsCount = 1
  while stackDepth > 0:
    let top = stackDepth - 1
    let vertex = stackVertices[top]
    if stackNextEdge[top] >= degree[vertex]:
      dec stackDepth
      continue
    let edge = stackNextEdge[top]
    inc stackNextEdge[top]
    let neighbor = int(adjacency[vertex * MaxDegree + edge])
    if not visited[neighbor]:
      visited[neighbor] = true
      encodedValues[resultLength] = int64(97 + neighbor)
      inc resultLength
      inc dfsCount
      stackVertices[stackDepth] = neighbor
      stackNextEdge[stackDepth] = 0
      inc stackDepth
  encodedValues[dfsCountSlot] = int64(dfsCount)

  let outputBytes = resultLength * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< resultLength:
    storeI64Le(output, index * 8, encodedValues[index])
  int64(outputBytes)
