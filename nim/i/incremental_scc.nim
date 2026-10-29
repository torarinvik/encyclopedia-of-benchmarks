const
  MaxVertices = 8
  MaxEdges = 32
  MaxInputLength = 2 + 2 * MaxEdges
  ReachabilityCells = MaxVertices * MaxVertices

proc incremental_scc*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "incremental_scc".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  if input[0] < 1 or input[0] > int64(MaxVertices) or input[1] < 0 or input[1] > int64(MaxEdges): return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 2 + 2 * edgeCount: return -1

  var sources: array[MaxEdges, int]
  var destinations: array[MaxEdges, int]
  for edge in 0 ..< edgeCount:
    let source = input[2 + 2 * edge]
    let destination = input[3 + 2 * edge]
    if source < 0 or destination < 0 or source >= int64(vertexCount) or destination >= int64(vertexCount): return -1
    sources[edge] = int(source)
    destinations[edge] = int(destination)

  var reachable: array[ReachabilityCells, bool]
  for vertex in 0 ..< vertexCount:
    reachable[vertex * MaxVertices + vertex] = true
  var checksum = 0'i64
  for edge in 0 ..< edgeCount:
    let source = sources[edge]
    let destination = destinations[edge]
    var predecessors: array[MaxVertices, bool]
    var successors: array[MaxVertices, bool]
    for vertex in 0 ..< vertexCount:
      predecessors[vertex] = reachable[vertex * MaxVertices + source]
      successors[vertex] = reachable[destination * MaxVertices + vertex]
    for first in 0 ..< vertexCount:
      for second in 0 ..< vertexCount:
        if predecessors[first] and successors[second]:
          reachable[first * MaxVertices + second] = true

    var assigned: array[MaxVertices, bool]
    var componentCount = 0'i64
    for first in 0 ..< vertexCount:
      if assigned[first]: continue
      inc componentCount
      for vertex in first ..< vertexCount:
        if reachable[first * MaxVertices + vertex] and reachable[vertex * MaxVertices + first]:
          assigned[vertex] = true
    checksum += int64(edge + 1) * componentCount
  checksum
