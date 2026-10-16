## Detect directed cycles with iterative three-color depth-first search.
proc check_cycle*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "check_cycle".} =
  const maxVertices = 32
  const maxEdges = 256
  const maxMatrix = maxVertices * maxVertices
  if input == nil or length < 2 or input[0] < 0 or input[0] > int64(maxVertices) or
      input[1] < 0 or input[1] > int64(maxEdges):
    return -1
  let vertices = int(input[0])
  let edges = int(input[1])
  if length != csize_t(2 + 2 * edges): return -1

  var adjacency: array[maxMatrix, bool]
  for edge in 0 ..< edges:
    let origin = input[2 + 2 * edge]
    let destination = input[3 + 2 * edge]
    if origin < 0 or origin >= int64(vertices) or destination < 0 or destination >= int64(vertices): return -1
    adjacency[int(origin) * maxVertices + int(destination)] = true

  var color: array[maxVertices, int]
  var stack: array[maxVertices, int]
  var nextNeighbor: array[maxVertices, int]
  for start in 0 ..< vertices:
    if color[start] != 0: continue
    var top = 1
    stack[0] = start
    nextNeighbor[0] = 0
    color[start] = 1
    while top > 0:
      let frame = top - 1
      let current = stack[frame]
      while nextNeighbor[frame] < vertices and not adjacency[current * maxVertices + nextNeighbor[frame]]:
        inc nextNeighbor[frame]
      if nextNeighbor[frame] == vertices:
        color[current] = 2
        dec top
        continue
      let neighbor = nextNeighbor[frame]
      inc nextNeighbor[frame]
      if color[neighbor] == 1: return 1
      if color[neighbor] == 0:
        color[neighbor] = 1
        stack[top] = neighbor
        nextNeighbor[top] = 0
        inc top
  return 0
