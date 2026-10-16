const MaxVertices = 64
const MaxEdges = 256
const MaxInputLength = 4 + 3 * MaxEdges
const MaxDequeCapacity = MaxVertices * MaxVertices + 1

proc breadth_first_search_zero_one_shortest_path*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "breadth_first_search_zero_one_shortest_path".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -2
  let vertexValue = input[0]
  let edgeValue = input[1]
  let startValue = input[2]
  let finishValue = input[3]
  if vertexValue < 1 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges: return -2
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  if length != csize_t(4 + 3 * edges) or startValue < 0 or startValue >= vertexValue or
      finishValue < 0 or finishValue >= vertexValue: return -2

  var edgeTo: array[MaxEdges, int]
  var edgeWeight: array[MaxEdges, int64]
  var nextEdge: array[MaxEdges, int]
  var headEdge: array[MaxVertices, int]
  var tailEdge: array[MaxVertices, int]
  for vertex in 0 ..< vertices:
    headEdge[vertex] = -1
    tailEdge[vertex] = -1
  for edge in 0 ..< edges:
    let fromValue = input[4 + 3 * edge]
    let toValue = input[5 + 3 * edge]
    let weightValue = input[6 + 3 * edge]
    if fromValue < 0 or fromValue >= vertexValue or toValue < 0 or toValue >= vertexValue or
        (weightValue != 0 and weightValue != 1): return -2
    let source = int(fromValue)
    edgeTo[edge] = int(toValue)
    edgeWeight[edge] = weightValue
    nextEdge[edge] = -1
    if headEdge[source] < 0: headEdge[source] = edge
    else: nextEdge[tailEdge[source]] = edge
    tailEdge[source] = edge

  let start = int(startValue)
  let finish = int(finishValue)
  var distance: array[MaxVertices, int64]
  for vertex in 0 ..< vertices: distance[vertex] = 1_000_000_000
  var deque: array[MaxDequeCapacity, int]
  var dequeHead = 0
  var dequeCount = 1
  distance[start] = 0
  deque[0] = start
  while dequeCount > 0:
    let node = deque[dequeHead]
    dequeHead = (dequeHead + 1) mod MaxDequeCapacity
    dec dequeCount
    var edge = headEdge[node]
    while edge >= 0:
      let neighbor = edgeTo[edge]
      let candidate = distance[node] + edgeWeight[edge]
      if candidate < distance[neighbor]:
        distance[neighbor] = candidate
        if edgeWeight[edge] == 0:
          dequeHead = (dequeHead + MaxDequeCapacity - 1) mod MaxDequeCapacity
          deque[dequeHead] = neighbor
        else:
          deque[(dequeHead + dequeCount) mod MaxDequeCapacity] = neighbor
        inc dequeCount
      edge = nextEdge[edge]
  if distance[finish] == 1_000_000_000: return -1
  distance[finish]
