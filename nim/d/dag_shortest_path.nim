const
  MaxVertices = 12
  MaxEdges = 66
  MaxLength = 203
  DistanceOffset = 100000'i64
  InfinityDistance = 1'i64 shl 60

proc dag_shortest_path*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dag_shortest_path".} =
  if input == nil or length < 4 or length > csize_t(MaxLength): return -1
  if input[0] < 1 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEdges: return -1
  let vertexCount = int(input[0])
  let edgeCount = int(input[1])
  if int(length) != 4 + 3 * edgeCount: return -1
  if input[2] < 0 or input[2] >= int64(vertexCount) or input[3] < 0 or input[3] >= int64(vertexCount): return -1
  var from, to, weight: array[MaxEdges, int64]
  var indegree: array[MaxVertices, int64]
  var queue, order: array[MaxVertices, int]
  for edge in 0 ..< edgeCount:
    let start = input[4 + 3 * edge]
    let finish = input[5 + 3 * edge]
    let cost = input[6 + 3 * edge]
    if start < 0 or start >= int64(vertexCount) or finish < 0 or finish >= int64(vertexCount): return -1
    if start == finish or cost < -1000 or cost > 1000: return -1
    for previous in 0 ..< edge:
      if from[previous] == start and to[previous] == finish: return -1
    from[edge] = start
    to[edge] = finish
    weight[edge] = cost
    inc indegree[int(finish)]
  var head = 0
  var tail = 0
  for vertex in 0 ..< vertexCount:
    if indegree[vertex] == 0:
      queue[tail] = vertex
      inc tail
  var orderCount = 0
  while head < tail:
    let vertex = queue[head]
    inc head
    order[orderCount] = vertex
    inc orderCount
    for edge in 0 ..< edgeCount:
      if from[edge] == int64(vertex):
        let finish = int(to[edge])
        dec indegree[finish]
        if indegree[finish] == 0:
          queue[tail] = finish
          inc tail
  if orderCount != vertexCount: return -1
  var distance: array[MaxVertices, int64]
  for vertex in 0 ..< vertexCount: distance[vertex] = InfinityDistance
  distance[int(input[2])] = 0
  for position in 0 ..< vertexCount:
    let vertex = order[position]
    if distance[vertex] == InfinityDistance: continue
    for edge in 0 ..< edgeCount:
      if from[edge] == int64(vertex):
        let finish = int(to[edge])
        let candidate = distance[vertex] + weight[edge]
        if candidate < distance[finish]: distance[finish] = candidate
  let answer = distance[int(input[3])]
  if answer == InfinityDistance: return 0
  DistanceOffset + answer
