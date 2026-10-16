const MaxVertices = 26
const MaxEdges = 256

proc breadth_first_search_shortest_path_distance*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "breadth_first_search_shortest_path_distance".} =
  if input.isNil or length < 4: return -1
  let verticesValue = input[0]
  let edgesValue = input[1]
  let sourceValue = input[2]
  let targetValue = input[3]
  if verticesValue < 1 or verticesValue > MaxVertices or edgesValue < 0 or edgesValue > MaxEdges: return -1
  let vertices = int(verticesValue)
  let edges = int(edgesValue)
  if sourceValue < 0 or sourceValue >= verticesValue or targetValue < 0 or targetValue >= verticesValue or
      length != csize_t(4 + 2 * edges): return -1

  var adjacent: array[MaxVertices * MaxVertices, bool]
  for edge in 0 ..< edges:
    let fromValue = input[4 + 2 * edge]
    let toValue = input[5 + 2 * edge]
    if fromValue < 0 or fromValue >= verticesValue or toValue < 0 or toValue >= verticesValue: return -1
    adjacent[int(fromValue) * vertices + int(toValue)] = true

  let source = int(sourceValue)
  let target = int(targetValue)
  var distance: array[MaxVertices, int64]
  var queue: array[MaxVertices, int]
  for vertex in 0 ..< vertices: distance[vertex] = -1
  var head = 0
  var tail = 1
  distance[source] = 0
  queue[0] = source
  while head < tail:
    let current = queue[head]
    inc head
    for next in 0 ..< vertices:
      if adjacent[current * vertices + next] and distance[next] < 0:
        distance[next] = distance[current] + 1
        queue[tail] = next
        inc tail
  distance[target]
