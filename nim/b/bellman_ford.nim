## Directed edge triples, separate reachability, and checked distance addition.
proc bellman_ford*(edges: ptr UncheckedArray[int64], vertices, edge_count, source: csize_t,
                   distances: ptr UncheckedArray[int64], reachable: ptr UncheckedArray[uint8]): int64 {.cdecl, exportc: "bellman_ford".} =
  if vertices == 0:
    return (if source == 0 and edge_count == 0: 0'i64 else: -3'i64)
  if source >= vertices:
    return -3
  var edge = csize_t(0)
  while edge < edge_count:
    let origin = edges[3 * edge]
    let destination = edges[3 * edge + 1]
    if origin < 0 or destination < 0 or uint64(origin) >= uint64(vertices) or uint64(destination) >= uint64(vertices):
      return -3
    inc edge
  var vertex = csize_t(0)
  while vertex < vertices:
    distances[vertex] = 0
    reachable[vertex] = 0
    inc vertex
  reachable[source] = 1
  var round = csize_t(0)
  while round < vertices:
    var changed = false
    edge = 0
    while edge < edge_count:
      let origin = csize_t(edges[3 * edge])
      let destination = csize_t(edges[3 * edge + 1])
      let weight = edges[3 * edge + 2]
      if reachable[origin] != 0:
        let base = distances[origin]
        if (weight > 0 and base > high(int64) - weight) or (weight < 0 and base < low(int64) - weight):
          return -2
        let candidate = base + weight
        if reachable[destination] == 0 or candidate < distances[destination]:
          if round == vertices - 1:
            return -1
          distances[destination] = candidate
          reachable[destination] = 1
          changed = true
      inc edge
    if not changed:
      return 0
    inc round
  return 0
