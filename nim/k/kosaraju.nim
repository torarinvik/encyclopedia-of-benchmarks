const
  MaxVertexCount = 40
  MaxEdgeCount = 2047
  MaxInputLength = 2 + 2 * MaxEdgeCount

proc fillOrder(adjacency: var array[MaxVertexCount, uint64], vertexCount, vertex: int,
    visited: var array[MaxVertexCount, bool], order: var array[MaxVertexCount, int], orderLength: var int) =
  visited[vertex] = true
  for neighbor in 0 ..< vertexCount:
    if (adjacency[vertex] and (1'u64 shl neighbor)) != 0'u64 and not visited[neighbor]:
      fillOrder(adjacency, vertexCount, neighbor, visited, order, orderLength)
  order[orderLength] = vertex
  inc orderLength

proc collectComponent(transpose: var array[MaxVertexCount, uint64], vertexCount, vertex: int,
    visited: var array[MaxVertexCount, bool], componentId: var array[MaxVertexCount, int], id: int) =
  visited[vertex] = true
  componentId[vertex] = id
  for neighbor in 0 ..< vertexCount:
    if (transpose[vertex] and (1'u64 shl neighbor)) != 0'u64 and not visited[neighbor]:
      collectComponent(transpose, vertexCount, neighbor, visited, componentId, id)

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

proc kosaraju*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "kosaraju".} =
  if input.isNil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 0'i64 or input[0] > MaxVertexCount or input[1] < 0'i64 or input[1] > MaxEdgeCount:
    return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 2 * edgeCount: return -1
  var adjacency: array[MaxVertexCount, uint64]
  var transpose: array[MaxVertexCount, uint64]
  for edge in 0 ..< edgeCount:
    let fromValue = input[2 + 2 * edge]
    let toValue = input[3 + 2 * edge]
    if fromValue < 0'i64 or toValue < 0'i64 or fromValue >= int64(vertexCount) or toValue >= int64(vertexCount):
      return -1
    let from = int(fromValue)
    let to = int(toValue)
    adjacency[from] = adjacency[from] or (1'u64 shl to)
    transpose[to] = transpose[to] or (1'u64 shl from)
  var visited: array[MaxVertexCount, bool]
  var order: array[MaxVertexCount, int]
  var orderLength = 0
  for vertex in 0 ..< vertexCount:
    if not visited[vertex]: fillOrder(adjacency, vertexCount, vertex, visited, order, orderLength)
  for vertex in 0 ..< MaxVertexCount: visited[vertex] = false
  var componentId: array[MaxVertexCount, int]
  for vertex in 0 ..< MaxVertexCount: componentId[vertex] = -1
  var componentCount = 0
  var index = orderLength
  while index > 0:
    dec index
    let vertex = order[index]
    if not visited[vertex]:
      collectComponent(transpose, vertexCount, vertex, visited, componentId, componentCount)
      inc componentCount
  encodeComponents(componentId, vertexCount, componentCount, output, outputCapacity)
