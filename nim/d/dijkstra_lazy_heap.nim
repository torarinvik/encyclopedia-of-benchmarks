const
  MaxVertices = 64
  MaxEdges = 256
  MaxHeap = MaxEdges + 1
  NoneIndex = MaxEdges

proc before(leftDistance: int64, leftVertex: int, rightDistance: int64, rightVertex: int): bool =
  leftDistance < rightDistance or (leftDistance == rightDistance and leftVertex < rightVertex)

proc dijkstra_lazy_heap*(edges: ptr UncheckedArray[int64], vertices, edgeCount, source: csize_t,
                         distances: ptr UncheckedArray[int64], reachable: ptr UncheckedArray[uint8]): int64
    {.cdecl, exportc: "dijkstra_lazy_heap".} =
  if vertices > csize_t(MaxVertices) or edgeCount > csize_t(MaxEdges): return -3
  if vertices == 0: return (if source == 0 and edgeCount == 0: 0 else: -3)
  if source >= vertices: return -3
  for edge in 0 ..< int(edgeCount):
    let origin = edges[3 * edge]
    let destination = edges[3 * edge + 1]
    let weight = edges[3 * edge + 2]
    if origin < 0 or origin >= int64(vertices) or destination < 0 or destination >= int64(vertices):
      return -3
    if weight < 0: return -4

  var head: array[MaxVertices, int]
  var tail: array[MaxVertices, int]
  var next: array[MaxEdges, int]
  for vertex in 0 ..< int(vertices):
    head[vertex] = NoneIndex
    tail[vertex] = NoneIndex
  for edge in 0 ..< int(edgeCount):
    let origin = int(edges[3 * edge])
    next[edge] = NoneIndex
    if head[origin] == NoneIndex: head[origin] = edge
    else: next[tail[origin]] = edge
    tail[origin] = edge

  for vertex in 0 ..< int(vertices):
    distances[vertex] = 0
    reachable[vertex] = 0
  var heapDistance: array[MaxHeap, int64]
  var heapVertex: array[MaxHeap, int]
  var heapCount = 1
  heapDistance[0] = 0
  heapVertex[0] = int(source)
  distances[int(source)] = 0
  reachable[int(source)] = 1

  while heapCount > 0:
    let current = heapDistance[0]
    let origin = heapVertex[0]
    dec heapCount
    if heapCount > 0:
      let lastDistance = heapDistance[heapCount]
      let lastVertex = heapVertex[heapCount]
      var position = 0
      while 2 * position + 1 < heapCount:
        var child = 2 * position + 1
        if child + 1 < heapCount and before(heapDistance[child + 1], heapVertex[child + 1],
                                            heapDistance[child], heapVertex[child]): inc child
        if not before(heapDistance[child], heapVertex[child], lastDistance, lastVertex): break
        heapDistance[position] = heapDistance[child]
        heapVertex[position] = heapVertex[child]
        position = child
      heapDistance[position] = lastDistance
      heapVertex[position] = lastVertex
    if current != distances[origin] or reachable[origin] == 2: continue
    reachable[origin] = 2

    var edge = head[origin]
    while edge != NoneIndex:
      let destination = int(edges[3 * edge + 1])
      let weight = edges[3 * edge + 2]
      if current > high(int64) - weight: return -2
      let candidate = current + weight
      if reachable[destination] != 2 and
          (reachable[destination] == 0 or candidate < distances[destination]):
        distances[destination] = candidate
        reachable[destination] = 1
        var position = heapCount
        inc heapCount
        while position > 0:
          let parent = (position - 1) div 2
          if not before(candidate, destination, heapDistance[parent], heapVertex[parent]): break
          heapDistance[position] = heapDistance[parent]
          heapVertex[position] = heapVertex[parent]
          position = parent
        heapDistance[position] = candidate
        heapVertex[position] = destination
      edge = next[edge]

  for vertex in 0 ..< int(vertices):
    if reachable[vertex] == 2: reachable[vertex] = 1
  return 0
