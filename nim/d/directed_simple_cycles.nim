## Enumerate directed simple cycles in source DFS order.
const MaxVertices = 6
const MaxEdges = MaxVertices * MaxVertices
const MaxOutputBytes = 2786

proc directed_simple_cycles*(input: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "directed_simple_cycles".} =
  if input == nil or length < 2: return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  if vertexValue < 0 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges: return -1
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  if int(length) != 2 + 2 * edges: return -1

  var adjacency: array[MaxVertices, array[MaxVertices, bool]]
  for edge in 0 ..< edges:
    let source = input[2 + 2 * edge]
    let destination = input[3 + 2 * edge]
    if source < 0 or source >= vertexValue or destination < 0 or destination >= vertexValue: return -1
    adjacency[int(source)][int(destination)] = true

  var scratch: array[MaxOutputBytes, uint8]
  var outputLength = 0
  for start in 0 ..< vertices:
    var path: array[MaxVertices, int]
    var nextNeighbor: array[MaxVertices, int]
    var visited: array[MaxVertices, bool]
    var depth = 0
    path[0] = start
    visited[start] = true
    while true:
      let current = path[depth]
      if nextNeighbor[depth] == vertices:
        visited[current] = false
        if depth == 0: break
        dec depth
        continue
      let neighbor = nextNeighbor[depth]
      inc nextNeighbor[depth]
      if not adjacency[current][neighbor]: continue
      if neighbor == start:
        for index in 0 .. depth:
          scratch[outputLength] = uint8(path[index])
          inc outputLength
        scratch[outputLength] = uint8(start); inc outputLength
        scratch[outputLength] = 255; inc outputLength
      elif not visited[neighbor]:
        inc depth
        path[depth] = neighbor
        nextNeighbor[depth] = 0
        visited[neighbor] = true
    for vertex in 0 ..< vertices:
      adjacency[start][vertex] = false
      adjacency[vertex][start] = false
  if outputLength == 0: return 0
  if output == nil or capacity < csize_t(outputLength): return -2
  for index in 0 ..< outputLength: output[index] = scratch[index]
  int64(outputLength)
