const
  maxVertices = 64
  maxEdges = 128
  maxArcs = 2 * maxEdges
  maxInputLength = 2 + 2 * maxEdges + 1

type
  Graph = object
    head: array[maxVertices, int]
    tail: array[maxVertices, int]
    to: array[maxArcs, int]
    next: array[maxArcs, int]
    arcEdge: array[maxArcs, int]
    edgeU: array[maxEdges, int]
    edgeUsed: array[maxEdges, bool]
    direction: array[maxEdges, int]
    discovery: array[maxVertices, int]
    low: array[maxVertices, int]
    timer: int
    bridges: int
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc appendArc(graph: var Graph, from, target, edge: int, arcCount: var int) =
  let arc = arcCount
  inc arcCount
  graph.to[arc] = target
  graph.arcEdge[arc] = edge
  graph.next[arc] = -1
  if graph.head[from] == -1: graph.head[from] = arc
  else: graph.next[graph.tail[from]] = arc
  graph.tail[from] = arc

proc visit(graph: var Graph, vertex: int) =
  graph.discovery[vertex] = graph.timer
  graph.low[vertex] = graph.timer
  inc graph.timer
  var arc = graph.head[vertex]
  while arc != -1:
    let nextArc = graph.next[arc]
    let edge = graph.arcEdge[arc]
    if not graph.edgeUsed[edge]:
      graph.edgeUsed[edge] = true
      graph.direction[edge] = if vertex == graph.edgeU[edge]: 1 else: -1
      let neighbor = graph.to[arc]
      if graph.discovery[neighbor] == -1:
        visit(graph, neighbor)
        if graph.low[neighbor] < graph.low[vertex]: graph.low[vertex] = graph.low[neighbor]
        if graph.low[neighbor] > graph.discovery[vertex]: inc graph.bridges
      elif graph.discovery[neighbor] < graph.low[vertex]:
        graph.low[vertex] = graph.discovery[neighbor]
    arc = nextArc

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc strong_orientation*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "strong_orientation".} =
  if input.isNil or length < 2 or length > maxInputLength.csize_t: return -1
  let rawVertices = input[0]
  let rawEdges = input[1]
  if rawVertices < 1'i64 or rawVertices > maxVertices or rawEdges < 0'i64 or rawEdges > maxEdges:
    return -1
  let vertexCount = int(rawVertices)
  let edgeCount = int(rawEdges)
  if int(length) != 2 + 2 * edgeCount: return -1
  for edge in 0 ..< edgeCount:
    let left = input[2 + 2 * edge]
    let right = input[3 + 2 * edge]
    if left < 0'i64 or right < 0'i64 or left >= rawVertices or right >= rawVertices: return -1
  let outputBytes = 8 * (edgeCount + 1)
  if output.isNil or outputCapacity < outputBytes.csize_t: return -2

  var graph: Graph
  for vertex in 0 ..< maxVertices:
    graph.head[vertex] = -1
    graph.tail[vertex] = -1
    graph.discovery[vertex] = -1
  var arcCount = 0
  for edge in 0 ..< edgeCount:
    let left = int(input[2 + 2 * edge])
    let right = int(input[3 + 2 * edge])
    graph.edgeU[edge] = left
    appendArc(graph, left, right, edge, arcCount)
    appendArc(graph, right, left, edge, arcCount)
  var components = 0
  for vertex in 0 ..< vertexCount:
    if graph.discovery[vertex] == -1:
      inc components
      visit(graph, vertex)
  storeI64Le(output, 0, int64(components + graph.bridges))
  for edge in 0 ..< edgeCount:
    storeI64Le(output, 8 * (edge + 1), int64(graph.direction[edge]))
  int64(outputBytes)
