## Detect cycles in a bounded simple undirected graph with iterative DFS.
proc undirected_cycle_check*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "undirected_cycle_check".} =
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
    let left = input[2 + 2 * edge]
    let right = input[3 + 2 * edge]
    if left < 0 or left >= int64(vertices) or right < 0 or right >= int64(vertices): return -1
    let forward = int(left) * maxVertices + int(right)
    let reverse = int(right) * maxVertices + int(left)
    if adjacency[forward]: return -1
    adjacency[forward] = true
    adjacency[reverse] = true

  var visited: array[maxVertices, bool]
  var stackVertex: array[maxVertices, int]
  var stackParent: array[maxVertices, int]
  for start in 0 ..< vertices:
    if visited[start]: continue
    var top = 1
    stackVertex[0] = start
    stackParent[0] = maxVertices
    visited[start] = true
    while top > 0:
      dec top
      let current = stackVertex[top]
      let parent = stackParent[top]
      for neighbor in 0 ..< vertices:
        if not adjacency[current * maxVertices + neighbor] or neighbor == parent: continue
        if visited[neighbor]: return 1
        visited[neighbor] = true
        stackVertex[top] = neighbor
        stackParent[top] = current
        inc top
  return 0
