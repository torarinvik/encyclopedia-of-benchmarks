## Directed cycle detection with iterative depth-first search and three colors.
proc cycle_check_directed_graph*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cycle_check_directed_graph".} =
  if values == nil or length < 1 or length > 65 or (length - 1) mod 2 != 0:
    return -1
  if values[0] < 0 or values[0] > 64:
    return -1
  let vertices = int(values[0])
  let edgeCount = int((length - 1) div 2)
  if edgeCount > 32:
    return -1
  var adjacency: array[64, uint64]
  var state: array[64, uint8]
  var stack: array[64, int]
  var nextNeighbor: array[64, int]
  for edge in 0 ..< edgeCount:
    let source = values[1 + 2 * edge]
    let destination = values[2 + 2 * edge]
    if source < 0 or destination < 0 or source >= values[0] or destination >= values[0]:
      return -1
    adjacency[int(source)] = adjacency[int(source)] or (1'u64 shl int(destination))

  for root in 0 ..< vertices:
    if state[root] != 0: continue
    var top = 0
    stack[0] = root
    nextNeighbor[0] = 0
    state[root] = 1
    while true:
      let node = stack[top]
      var destination = nextNeighbor[top]
      while destination < vertices and
          (adjacency[node] and (1'u64 shl destination)) == 0'u64:
        inc destination
      if destination == vertices:
        state[node] = 2
        if top == 0: break
        dec top
        continue
      nextNeighbor[top] = destination + 1
      if state[destination] == 1: return 1
      if state[destination] == 0:
        inc top
        stack[top] = destination
        nextNeighbor[top] = 0
        state[destination] = 1
  0
