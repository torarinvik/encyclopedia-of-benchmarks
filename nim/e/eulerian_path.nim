## Construct a directed Eulerian path with iterative Hierholzer traversal.
const MaxVertices = 32
const MaxEdges = 256

proc putI64(output: ptr UncheckedArray[uint8], byteOffset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[byteOffset + byte] = uint8((bits shr (byte * 8)) and 255)

proc eulerian_path*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "eulerian_path".} =
  if input == nil or length < 2: return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  if vertexValue < 0 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges: return -1
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  if int(length) != 2 + 2 * edges: return -1

  var adjacency: array[MaxVertices, array[MaxEdges, uint8]]
  var inDegree: array[MaxVertices, int]
  var outDegree: array[MaxVertices, int]
  for edge in 0 ..< edges:
    let source = input[2 + 2 * edge]
    let destination = input[3 + 2 * edge]
    if source < 0 or source >= vertexValue or destination < 0 or destination >= vertexValue: return -1
    let sourceIndex = int(source)
    let destinationIndex = int(destination)
    adjacency[sourceIndex][outDegree[sourceIndex]] = uint8(destinationIndex)
    inc outDegree[sourceIndex]
    inc inDegree[destinationIndex]
  if edges == 0: return 0

  var start = 0
  var startCount = 0
  var endCount = 0
  for vertex in 0 ..< vertices:
    let difference = outDegree[vertex] - inDegree[vertex]
    if difference == 1:
      start = vertex
      inc startCount
    elif difference == -1:
      inc endCount
    elif difference != 0:
      return 0
  if not ((startCount == 0 and endCount == 0) or (startCount == 1 and endCount == 1)): return 0
  if startCount == 0:
    while start < vertices and outDegree[start] == 0: inc start
    if start == vertices: return 0

  var remaining: array[MaxVertices, int]
  for vertex in 0 ..< vertices: remaining[vertex] = outDegree[vertex]
  var stack: array[MaxEdges + 1, int]
  var reversePath: array[MaxEdges + 1, int64]
  var top = 1
  var pathCount = 0
  stack[0] = start
  while top > 0:
    let current = stack[top - 1]
    if remaining[current] > 0:
      dec remaining[current]
      stack[top] = int(adjacency[current][remaining[current]])
      inc top
    else:
      dec top
      reversePath[pathCount] = int64(stack[top])
      inc pathCount
  if pathCount != edges + 1: return 0
  let bytes = pathCount * 8
  if output == nil or int(capacity) < bytes: return -2
  for index in 0 ..< pathCount:
    putI64(output, index * 8, reversePath[pathCount - index - 1])
  int64(bytes)
