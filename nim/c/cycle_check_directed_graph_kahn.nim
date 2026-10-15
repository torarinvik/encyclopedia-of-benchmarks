## Directed cycle detection with Kahn's zero-indegree queue.
proc cycle_check_directed_graph_kahn*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cycle_check_directed_graph_kahn".} =
  if values == nil or length < 1 or length > 65 or (length - 1) mod 2 != 0:
    return -1
  if values[0] < 0 or values[0] > 64:
    return -1
  let vertices = int(values[0])
  let edgeCount = int((length - 1) div 2)
  if edgeCount > 32:
    return -1
  var adjacency: array[64, uint64]
  var indegree: array[64, int]
  for edge in 0 ..< edgeCount:
    let source = values[1 + 2 * edge]
    let destination = values[2 + 2 * edge]
    if source < 0 or destination < 0 or source >= values[0] or destination >= values[0]:
      return -1
    let sourceIndex = int(source)
    let destinationIndex = int(destination)
    let mask = 1'u64 shl destinationIndex
    if (adjacency[sourceIndex] and mask) == 0'u64:
      adjacency[sourceIndex] = adjacency[sourceIndex] or mask
      inc indegree[destinationIndex]

  var queue: array[64, int]
  var head = 0
  var tail = 0
  for vertex in 0 ..< vertices:
    if indegree[vertex] == 0:
      queue[tail] = vertex
      inc tail
  var removed = 0
  while head < tail:
    let source = queue[head]
    inc head
    inc removed
    for destination in 0 ..< vertices:
      if (adjacency[source] and (1'u64 shl destination)) != 0'u64:
        dec indegree[destination]
        if indegree[destination] == 0:
          queue[tail] = destination
          inc tail
  if removed != vertices: 1 else: 0
