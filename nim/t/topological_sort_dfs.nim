## Deterministic depth-first topological sort with three-color cycle detection.
proc topological_sort_dfs*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "topological_sort_dfs".} =
  if values == nil or length < 1 or length > 66 or (length - 1) mod 2 != 0:
    return -2
  if values[0] < 0 or values[0] > 40:
    return -2
  let vertices = csize_t(values[0])
  let edgeCount = (length - 1) div 2
  var adjacency: array[40, uint64]
  var state: array[40, uint8]
  var stack: array[40, csize_t]
  var nextNeighbor: array[40, csize_t]
  var order: array[40, csize_t]

  for edge in 0'u64 ..< uint64(edgeCount):
    let originValue = values[1 + 2 * csize_t(edge)]
    let destinationValue = values[2 + 2 * csize_t(edge)]
    if originValue < 0 or destinationValue < 0 or
        uint64(originValue) >= uint64(vertices) or uint64(destinationValue) >= uint64(vertices):
      return -2
    let origin = csize_t(originValue)
    let destination = csize_t(destinationValue)
    adjacency[origin] = adjacency[origin] or (1'u64 shl int(destination))

  var count = csize_t(0)
  for root in 0'u64 ..< uint64(vertices):
    let rootIndex = csize_t(root)
    if state[rootIndex] != 0: continue
    var top = csize_t(0)
    stack[top] = rootIndex
    nextNeighbor[top] = 0
    state[rootIndex] = 1
    while true:
      let origin = stack[top]
      var destination = nextNeighbor[top]
      while destination < vertices and
          (adjacency[origin] and (1'u64 shl int(destination))) == 0'u64:
        inc destination
      if destination == vertices:
        state[origin] = 2
        order[count] = origin
        inc count
        if top == 0: break
        dec top
        continue
      nextNeighbor[top] = destination + 1
      if state[destination] == 1: return -1
      if state[destination] == 0:
        inc top
        stack[top] = destination
        nextNeighbor[top] = 0
        state[destination] = 1

  if outputCapacity < vertices or (vertices != 0 and output == nil):
    return -2
  for index in 0'u64 ..< uint64(count):
    output[csize_t(index)] = uint8(order[count - 1 - csize_t(index)])
  int64(count)
