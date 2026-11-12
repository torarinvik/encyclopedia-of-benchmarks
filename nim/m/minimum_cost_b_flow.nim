const
  maxVertices = 8
  maxEdges = 10
  maxArcs = 2 * maxEdges + 2 * maxVertices
  maxNodes = maxVertices + 2
  maxInputLength = 2 + maxVertices + 5 * maxEdges + 1
  maxOutputWords = 2 + maxVertices + maxEdges

type
  ResidualGraph = object
    fromVertex: array[maxArcs, int]
    toVertex: array[maxArcs, int]
    reverse: array[maxArcs, int]
    capacity: array[maxArcs, int64]
    cost: array[maxArcs, int64]
    arcCount: int
    originalArcCount: int
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc addEdge(graph: var ResidualGraph, fromVertex, toVertex: int, capacity, cost: int64) =
  let forward = graph.arcCount
  let backward = forward + 1
  graph.arcCount += 2
  graph.fromVertex[forward] = fromVertex
  graph.toVertex[forward] = toVertex
  graph.reverse[forward] = backward
  graph.capacity[forward] = capacity
  graph.cost[forward] = cost
  graph.fromVertex[backward] = toVertex
  graph.toVertex[backward] = fromVertex
  graph.reverse[backward] = forward
  graph.capacity[backward] = 0
  graph.cost[backward] = -cost

proc feasibleFlow(graph: var ResidualGraph, vertexCount: int, requiredFlow: int64): bool =
  let superSource = vertexCount
  let superSink = vertexCount + 1
  var sent = 0'i64
  while sent < requiredFlow:
    var parent: array[maxNodes, int]
    var seen: array[maxNodes, bool]
    var queue: array[maxNodes, int]
    for vertex in 0 ..< maxNodes: parent[vertex] = -1
    var head = 0
    var length = 0
    seen[superSource] = true
    queue[length] = superSource
    inc length
    while head < length:
      let vertex = queue[head]
      inc head
      for edge in 0 ..< graph.arcCount:
        let neighbor = graph.toVertex[edge]
        if graph.fromVertex[edge] == vertex and graph.capacity[edge] > 0 and not seen[neighbor]:
          seen[neighbor] = true
          parent[neighbor] = edge
          queue[length] = neighbor
          inc length
    if not seen[superSink]: return false
    var amount = requiredFlow - sent
    var vertex = superSink
    while vertex != superSource:
      let edge = parent[vertex]
      amount = min(amount, graph.capacity[edge])
      vertex = graph.fromVertex[edge]
    vertex = superSink
    while vertex != superSource:
      let edge = parent[vertex]
      graph.capacity[edge] -= amount
      graph.capacity[graph.reverse[edge]] += amount
      vertex = graph.fromVertex[edge]
    sent += amount
  true

proc cancelNegativeCycles(graph: var ResidualGraph, vertexCount: int): bool =
  if vertexCount == 0: return true
  while true:
    var distance: array[maxVertices, int64]
    var parent: array[maxVertices, int]
    for vertex in 0 ..< maxVertices: parent[vertex] = -1
    var changedVertex = -1
    for _ in 0 ..< vertexCount:
      changedVertex = -1
      for edge in 0 ..< graph.originalArcCount:
        let fromVertex = graph.fromVertex[edge]
        let toVertex = graph.toVertex[edge]
        if graph.capacity[edge] > 0 and distance[toVertex] > distance[fromVertex] + graph.cost[edge]:
          distance[toVertex] = distance[fromVertex] + graph.cost[edge]
          parent[toVertex] = edge
          changedVertex = toVertex
      if changedVertex == -1: break
    if changedVertex == -1: return true
    var onCycle = changedVertex
    for _ in 0 ..< vertexCount:
      let edge = parent[onCycle]
      if edge < 0: return false
      onCycle = graph.fromVertex[edge]
    var amount = high(int64)
    var vertex = onCycle
    while true:
      let edge = parent[vertex]
      if edge < 0: return false
      amount = min(amount, graph.capacity[edge])
      vertex = graph.fromVertex[edge]
      if vertex == onCycle: break
    vertex = onCycle
    while true:
      let edge = parent[vertex]
      graph.capacity[edge] -= amount
      graph.capacity[graph.reverse[edge]] += amount
      vertex = graph.fromVertex[edge]
      if vertex == onCycle: break

proc solve(vertexCount, edgeCount: int, input: I64Input,
    words: var array[maxOutputWords, int64]): bool =
  let edgeOffset = 2 + vertexCount
  var required: array[maxVertices, int64]
  for vertex in 0 ..< vertexCount: required[vertex] = input[2 + vertex]
  for edge in 0 ..< edgeCount:
    let offset = edgeOffset + 5 * edge
    let fromVertex = int(input[offset])
    let toVertex = int(input[offset + 1])
    let lower = input[offset + 2]
    required[fromVertex] -= lower
    required[toVertex] += lower
  var sum = 0'i64
  var requiredFlow = 0'i64
  for vertex in 0 ..< vertexCount:
    sum += required[vertex]
    if required[vertex] > 0: requiredFlow += required[vertex]
  if sum != 0: return false
  var graph: ResidualGraph
  for edge in 0 ..< edgeCount:
    let offset = edgeOffset + 5 * edge
    addEdge(graph, int(input[offset]), int(input[offset + 1]),
      input[offset + 3] - input[offset + 2], input[offset + 4])
  graph.originalArcCount = graph.arcCount
  for vertex in 0 ..< vertexCount:
    if required[vertex] > 0: addEdge(graph, vertexCount, vertex, required[vertex], 0)
    elif required[vertex] < 0: addEdge(graph, vertex, vertexCount + 1, -required[vertex], 0)
  if not feasibleFlow(graph, vertexCount, requiredFlow) or not cancelNegativeCycles(graph, vertexCount):
    return false
  var potential: array[maxVertices, int64]
  if vertexCount > 1:
    for _ in 0 ..< vertexCount - 1:
      var changed = false
      for edge in 0 ..< graph.originalArcCount:
        let fromVertex = graph.fromVertex[edge]
        let toVertex = graph.toVertex[edge]
        if graph.capacity[edge] > 0 and potential[toVertex] > potential[fromVertex] + graph.cost[edge]:
          potential[toVertex] = potential[fromVertex] + graph.cost[edge]
          changed = true
      if not changed: break
  words[0] = 1
  words[1] = 0
  for vertex in 0 ..< vertexCount: words[2 + vertex] = potential[vertex]
  for edge in 0 ..< edgeCount:
    let offset = edgeOffset + 5 * edge
    let flow = input[offset + 3] - graph.capacity[2 * edge]
    words[2 + vertexCount + edge] = flow
    words[1] += flow * input[offset + 4]
  true

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc minimum_cost_b_flow*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "minimum_cost_b_flow".} =
  if input.isNil or length < 2 or length > maxInputLength.csize_t: return -1
  let rawN = input[0]
  let rawM = input[1]
  if rawN < 0'i64 or rawN > maxVertices or rawM < 0'i64 or rawM > maxEdges: return -1
  let vertexCount = int(rawN)
  let edgeCount = int(rawM)
  if int(length) != 2 + vertexCount + 5 * edgeCount: return -1
  for vertex in 0 ..< vertexCount:
    if input[2 + vertex] < -5'i64 or input[2 + vertex] > 5'i64: return -1
  let edgeOffset = 2 + vertexCount
  for edge in 0 ..< edgeCount:
    let offset = edgeOffset + 5 * edge
    let fromVertex = input[offset]
    let toVertex = input[offset + 1]
    let lower = input[offset + 2]
    let upper = input[offset + 3]
    let cost = input[offset + 4]
    if fromVertex < 0'i64 or fromVertex >= rawN or toVertex < 0'i64 or toVertex >= rawN or
        lower < -3'i64 or upper > 3'i64 or lower > upper or upper - lower > 2 or cost < -4'i64 or cost > 4'i64:
      return -1
  let outputWords = 2 + vertexCount + edgeCount
  let outputBytes = 8 * outputWords
  if output.isNil or outputCapacity < outputBytes.csize_t: return -2
  var words: array[maxOutputWords, int64]
  if not solve(vertexCount, edgeCount, input, words):
    for word in 0 ..< outputWords: words[word] = 0
  for word in 0 ..< outputWords: storeI64Le(output, word * 8, words[word])
  int64(outputBytes)
