const
  MaxVertexCount = 40
  MaxEdgeCount = 2047
  MaxInputLength = 2 + 2 * MaxEdgeCount

proc visitVertex(adjacency: var array[MaxVertexCount, uint64], vertexCount, vertex: int,
    onStack: var array[MaxVertexCount, bool], stack: var array[MaxVertexCount, int], stackLength: var int,
    discovery, low, componentId: var array[MaxVertexCount, int], time, componentCount: var int) =
  discovery[vertex] = time
  low[vertex] = time
  inc time
  onStack[vertex] = true
  stack[stackLength] = vertex
  inc stackLength
  for neighbor in 0 ..< vertexCount:
    if (adjacency[vertex] and (1'u64 shl neighbor)) == 0'u64: continue
    if discovery[neighbor] == -1:
      visitVertex(adjacency, vertexCount, neighbor, onStack, stack, stackLength,
                  discovery, low, componentId, time, componentCount)
      if low[neighbor] < low[vertex]: low[vertex] = low[neighbor]
    elif onStack[neighbor] and discovery[neighbor] < low[vertex]:
      low[vertex] = discovery[neighbor]
  if low[vertex] == discovery[vertex]:
    while stackLength > 0:
      dec stackLength
      let member = stack[stackLength]
      onStack[member] = false
      componentId[member] = componentCount
      if member == vertex: break
    inc componentCount

proc encodeComponents(componentId: var array[MaxVertexCount, int], vertexCount, componentCount: int,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 =
  let outputLength = 1 + vertexCount + componentCount
  if outputCapacity < csize_t(outputLength) or output.isNil: return -2
  output[0] = uint8(componentCount)
  var position = 1
  for first in 0 ..< vertexCount:
    let id = componentId[first]
    var emitted = false
    for earlier in 0 ..< first:
      if componentId[earlier] == id: emitted = true
    if emitted: continue
    var componentSize = 0
    for member in first ..< vertexCount:
      if componentId[member] == id: inc componentSize
    output[position] = uint8(componentSize)
    inc position
    for member in first ..< vertexCount:
      if componentId[member] == id:
        output[position] = uint8(member)
        inc position
  int64(outputLength)

proc tarjan_scc*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tarjan_scc".} =
  if input.isNil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 0'i64 or input[0] > MaxVertexCount or input[1] < 0'i64 or input[1] > MaxEdgeCount:
    return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 2 * edgeCount: return -1
  var adjacency: array[MaxVertexCount, uint64]
  for edge in 0 ..< edgeCount:
    let fromValue = input[2 + 2 * edge]
    let toValue = input[3 + 2 * edge]
    if fromValue < 0'i64 or toValue < 0'i64 or fromValue >= int64(vertexCount) or toValue >= int64(vertexCount):
      return -1
    adjacency[int(fromValue)] = adjacency[int(fromValue)] or (1'u64 shl int(toValue))
  var onStack: array[MaxVertexCount, bool]
  var stack: array[MaxVertexCount, int]
  var discovery: array[MaxVertexCount, int]
  var low: array[MaxVertexCount, int]
  var componentId: array[MaxVertexCount, int]
  for vertex in 0 ..< MaxVertexCount:
    discovery[vertex] = -1
    componentId[vertex] = -1
  var stackLength = 0
  var time = 0
  var componentCount = 0
  for vertex in 0 ..< vertexCount:
    if discovery[vertex] == -1:
      visitVertex(adjacency, vertexCount, vertex, onStack, stack, stackLength,
                  discovery, low, componentId, time, componentCount)
  encodeComponents(componentId, vertexCount, componentCount, output, outputCapacity)
