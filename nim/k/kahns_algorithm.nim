const MaxVertices = 32
const MaxEdges = 128
const MaxInputLength = 1 + 2 * MaxEdges

proc findVertex(labels: openArray[int32], vertexCount: int, label: int32): int =
  for index in 0 ..< vertexCount:
    if labels[index] == label: return index
  -1

proc kahns_algorithm*(input: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "kahns_algorithm".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let edgeCountValue = input[0]
  if edgeCountValue < 0 or edgeCountValue > MaxEdges: return -1
  let edgeCount = int(edgeCountValue)
  if length != csize_t(1 + 2 * edgeCount): return -1

  var labels: array[MaxVertices, int32]
  var firstEdge: array[MaxVertices, int]
  var tailEdge: array[MaxVertices, int]
  var nextEdge: array[MaxEdges, int]
  var toByEdge: array[MaxEdges, int]
  var indegree: array[MaxVertices, int]
  var vertexCount = 0
  for vertex in 0 ..< MaxVertices:
    firstEdge[vertex] = -1
    tailEdge[vertex] = -1
  for edge in 0 ..< edgeCount:
    let fromValue = input[1 + 2 * edge]
    let toValue = input[2 + 2 * edge]
    if fromValue < int64(low(int32)) or fromValue > int64(high(int32)) or
       toValue < int64(low(int32)) or toValue > int64(high(int32)): return -1
    let fromLabel = int32(fromValue)
    let toLabel = int32(toValue)
    var fromIndex = findVertex(labels, vertexCount, fromLabel)
    if fromIndex < 0:
      if vertexCount >= MaxVertices: return -1
      fromIndex = vertexCount
      labels[vertexCount] = fromLabel
      inc vertexCount
    var toIndex = findVertex(labels, vertexCount, toLabel)
    if toIndex < 0:
      if vertexCount >= MaxVertices: return -1
      toIndex = vertexCount
      labels[vertexCount] = toLabel
      inc vertexCount
    toByEdge[edge] = toIndex
    nextEdge[edge] = -1
    if firstEdge[fromIndex] < 0:
      firstEdge[fromIndex] = edge
    else:
      nextEdge[tailEdge[fromIndex]] = edge
    tailEdge[fromIndex] = edge
    inc indegree[toIndex]

  var queue: array[MaxVertices, int]
  var order: array[MaxVertices, int]
  var queueHead = 0
  var queueTail = 0
  var orderCount = 0
  for vertex in 0 ..< vertexCount:
    if indegree[vertex] == 0:
      queue[queueTail] = vertex
      inc queueTail
  if vertexCount > 0 and queueTail != 1: return -1
  while queueHead < queueTail:
    if queueTail - queueHead != 1: return -1
    let current = queue[queueHead]
    inc queueHead
    order[orderCount] = current
    inc orderCount
    var outgoing = firstEdge[current]
    while outgoing >= 0:
      let adjacent = toByEdge[outgoing]
      if indegree[adjacent] == 0: return -1
      dec indegree[adjacent]
      if indegree[adjacent] == 0:
        queue[queueTail] = adjacent
        inc queueTail
      outgoing = nextEdge[outgoing]
  if orderCount != vertexCount: return -1

  let outputBytes = csize_t(4 * orderCount)
  if output.isNil or capacity < outputBytes: return -2
  for index in 0 ..< orderCount:
    var bits = cast[uint32](labels[order[index]])
    for byte in 0 ..< 4:
      output[4 * index + byte] = uint8(bits and 255'u32)
      bits = bits shr 8
  int64(outputBytes)
