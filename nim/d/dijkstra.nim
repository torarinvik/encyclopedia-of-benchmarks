## Directed edge triples, nonnegative weights, separate reachability.
proc dijkstra*(edges: ptr UncheckedArray[int64], vertices, edge_count, source: csize_t,
               distances: ptr UncheckedArray[int64], reachable: ptr UncheckedArray[uint8]): int64 {.cdecl, exportc: "dijkstra".} =
  if vertices == 0:
    return (if source == 0 and edge_count == 0: 0'i64 else: -3'i64)
  if source >= vertices:
    return -3
  var edge = csize_t(0)
  while edge < edge_count:
    let origin = edges[3 * edge]
    let destination = edges[3 * edge + 1]
    let weight = edges[3 * edge + 2]
    if origin < 0 or destination < 0 or uint64(origin) >= uint64(vertices) or uint64(destination) >= uint64(vertices):
      return -3
    if weight < 0:
      return -4
    inc edge
  var vertex = csize_t(0)
  while vertex < vertices:
    distances[vertex] = 0
    reachable[vertex] = 0
    inc vertex
  reachable[source] = 1
  var round = csize_t(0)
  while round < vertices:
    var selected = vertices
    var best = 0'i64
    vertex = 0
    while vertex < vertices:
      if reachable[vertex] == 1 and (selected == vertices or distances[vertex] < best):
        selected = vertex
        best = distances[vertex]
      inc vertex
    if selected == vertices:
      break
    reachable[selected] = 2
    edge = 0
    while edge < edge_count:
      if csize_t(edges[3 * edge]) == selected:
        let destination = csize_t(edges[3 * edge + 1])
        let weight = edges[3 * edge + 2]
        let base = distances[selected]
        if base > high(int64) - weight:
          return -2
        let candidate = base + weight
        if reachable[destination] != 2 and (reachable[destination] == 0 or candidate < distances[destination]):
          distances[destination] = candidate
          reachable[destination] = 1
      inc edge
    inc round
  vertex = 0
  while vertex < vertices:
    if reachable[vertex] == 2:
      reachable[vertex] = 1
    inc vertex
  return 0
