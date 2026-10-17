const
  MaxVertices = 32
  MaxEdges = 128
  MaxInputLength = 2 + 2 * MaxEdges

proc kahns_algorithm_long*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kahns_algorithm_long".} =
  if values == nil or length < 2 or length > MaxInputLength: return -1
  let vertexCount = values[0]
  let edgeCount = values[1]
  if vertexCount < 1 or vertexCount > MaxVertices or edgeCount < 0 or edgeCount > MaxEdges: return -1
  if length != csize_t(2 + 2 * edgeCount): return -1

  var multiplicity: array[MaxVertices * MaxVertices, int64]
  var indegree: array[MaxVertices, int64]
  var distance: array[MaxVertices, int64]
  var queue: array[MaxVertices, int64]
  for vertex in 0 ..< int(vertexCount): distance[vertex] = 1
  for edge in 0 ..< int(edgeCount):
    let source = values[2 + 2 * edge]
    let destination = values[3 + 2 * edge]
    if source < 0 or source >= vertexCount or destination < 0 or destination >= vertexCount: return -1
    multiplicity[int(source * MaxVertices + destination)] += 1
    indegree[int(destination)] += 1

  var head = 0
  var tail = 0
  for vertex in 0 ..< int(vertexCount):
    if indegree[vertex] == 0:
      queue[tail] = int64(vertex)
      inc tail
  var processed = 0'i64
  var maximum = 1'i64
  while head < tail:
    let source = int(queue[head])
    inc head
    inc processed
    if distance[source] > maximum: maximum = distance[source]
    for destination in 0 ..< int(vertexCount):
      let copies = multiplicity[source * MaxVertices + destination]
      if copies == 0: continue
      let candidate = distance[source] + 1
      if candidate > distance[destination]: distance[destination] = candidate
      for copy in 0 ..< int(copies):
        dec indegree[destination]
        if indegree[destination] == 0:
          queue[tail] = int64(destination)
          inc tail
  if processed != vertexCount: return -1
  for vertex in 0 ..< int(vertexCount):
    if distance[vertex] > maximum: maximum = distance[vertex]
  maximum
