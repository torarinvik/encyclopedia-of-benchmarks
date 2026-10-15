const MaxVertices = 256
const MaxEdges = 4096
const Inf = high(int64) div 4

proc a_star_search*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "a_star_search".} =
  if input == nil or length < 5 or length > csize_t(4 + MaxVertices + 2 * MaxEdges): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  if vertexValue < 1 or vertexValue > MaxVertices or edgeValue < 0 or edgeValue > MaxEdges or
      sourceValue < 0 or sourceValue >= vertexValue or targetValue < 0 or targetValue >= vertexValue:
    return -1
  let vertices = int(vertexValue)
  let edges = int(edgeValue)
  let source = int(sourceValue)
  let target = int(targetValue)
  if int(length) != 4 + vertices + 2 * edges: return -1

  var heuristic: array[MaxVertices, int64]
  var fromVertex: array[MaxEdges, int64]
  var toVertex: array[MaxEdges, int64]
  var distance: array[MaxVertices, int64]
  var parent: array[MaxVertices, int64]
  var reversed: array[MaxVertices, int64]
  var opened: array[MaxVertices, bool]
  var closed: array[MaxVertices, bool]
  for vertex in 0 ..< vertices:
    heuristic[vertex] = input[4 + vertex]
    if heuristic[vertex] < 0 or heuristic[vertex] > 1_000_000_000: return -1
    distance[vertex] = Inf
    parent[vertex] = -1
  if heuristic[target] != 0: return -1
  let edgeOffset = 4 + vertices
  for edge in 0 ..< edges:
    let u = input[edgeOffset + 2 * edge]
    let v = input[edgeOffset + 2 * edge + 1]
    if u < 0 or u >= vertexValue or v < 0 or v >= vertexValue or
        heuristic[int(u)] > heuristic[int(v)] + 1: return -1
    fromVertex[edge] = u
    toVertex[edge] = v

  distance[source] = 0
  opened[source] = true
  while true:
    var best = vertices
    for vertex in 0 ..< vertices:
      if not opened[vertex]: continue
      if best == vertices or distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] or
          (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] and
           (distance[vertex] < distance[best] or
            (distance[vertex] == distance[best] and vertex < best))):
        best = vertex
    if best == vertices: break
    opened[best] = false
    closed[best] = true
    if best == target: break
    for edge in 0 ..< edges:
      if int(fromVertex[edge]) != best: continue
      let neighbor = int(toVertex[edge])
      if closed[neighbor]: continue
      let candidate = distance[best] + 1
      if candidate < distance[neighbor]:
        distance[neighbor] = candidate
        parent[neighbor] = int64(best)
        opened[neighbor] = true
  if distance[target] == Inf: return 0
  var pathLength = 0
  var current = int64(target)
  while current >= 0 and pathLength < vertices:
    reversed[pathLength] = current
    inc pathLength
    if int(current) == source: break
    current = parent[int(current)]
  if pathLength == 0 or int(reversed[pathLength - 1]) != source or pathLength - 1 > 30: return -1
  if outputCapacity < csize_t(pathLength) or output == nil: return -2
  for index in 0 ..< pathLength:
    output[index] = uint8(reversed[pathLength - 1 - index])
  int64(pathLength)
