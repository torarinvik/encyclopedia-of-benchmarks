## Compute bounded all-pairs shortest paths and return one source row.
const MaxVertices = 64
const FloydStorage = MaxVertices * MaxVertices

proc floydWarshall*(edges: ptr UncheckedArray[int64], vertices, edgeCount, source: csize_t,
    distances: ptr UncheckedArray[int64], reachable: ptr UncheckedArray[uint8]): int64
    {.cdecl, exportc: "floyd_warshall".} =
  if vertices == 0: return (if source == 0 and edgeCount == 0: 0'i64 else: -3'i64)
  if vertices > MaxVertices or source >= vertices: return -3
  for edge in 0 ..< int(edgeCount):
    let origin = edges[3 * edge]
    let destination = edges[3 * edge + 1]
    if origin < 0 or destination < 0 or uint64(origin) >= uint64(vertices) or uint64(destination) >= uint64(vertices):
      return -3

  var allDistances: array[FloydStorage, int64]
  var present: array[FloydStorage, uint8]
  for vertex in 0 ..< int(vertices): present[vertex * int(vertices) + vertex] = 1
  for edge in 0 ..< int(edgeCount):
    let origin = int(edges[3 * edge])
    let destination = int(edges[3 * edge + 1])
    let index = origin * int(vertices) + destination
    let weight = edges[3 * edge + 2]
    if present[index] == 0 or weight < allDistances[index]:
      allDistances[index] = weight
      present[index] = 1
  for middle in 0 ..< int(vertices):
    for origin in 0 ..< int(vertices):
      let leftIndex = origin * int(vertices) + middle
      if present[leftIndex] == 0: continue
      for destination in 0 ..< int(vertices):
        let rightIndex = middle * int(vertices) + destination
        if present[rightIndex] == 0: continue
        let left = allDistances[leftIndex]
        let right = allDistances[rightIndex]
        if (right > 0 and left > high(int64) - right) or
            (right < 0 and left < low(int64) - right): return -2
        let candidate = left + right
        let index = origin * int(vertices) + destination
        if present[index] == 0 or candidate < allDistances[index]:
          allDistances[index] = candidate
          present[index] = 1
  for vertex in 0 ..< int(vertices):
    let index = int(source) * int(vertices) + vertex
    if present[index] != 0 and present[vertex * int(vertices) + vertex] != 0 and
        allDistances[vertex * int(vertices) + vertex] < 0: return -1
  for vertex in 0 ..< int(vertices):
    let index = int(source) * int(vertices) + vertex
    reachable[vertex] = present[index]
    distances[vertex] = if present[index] != 0: allDistances[index] else: 0
  0
