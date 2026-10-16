const
  MaxVertices = 64
  MaxEdges = 256
  MaxInputLength = 2 + 2 * MaxEdges
  MaxCells = MaxVertices * MaxVertices

type I64Input = ptr UncheckedArray[int64]

proc bipartite_graph_dfs*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "bipartite_graph_dfs".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxVertices) or m64 < 0 or m64 > int64(MaxEdges): return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + 2 * m): return -1

  var adjacency: array[MaxCells, bool]
  for edge in 0..<m:
    let from64 = input[2 + 2 * edge]
    let to64 = input[3 + 2 * edge]
    if from64 < 0 or from64 >= n64 or to64 < 0 or to64 >= n64: return -1
    let from = int(from64)
    let to = int(to64)
    adjacency[from * n + to] = true
    adjacency[to * n + from] = true

  var color: array[MaxVertices, int]
  var stack: array[MaxVertices, int]
  for i in 0..<n: color[i] = -1
  for start in 0..<n:
    if color[start] != -1: continue
    var top = 1
    stack[0] = start
    color[start] = 0
    while top > 0:
      dec top
      let node = stack[top]
      for neighbor in 0..<n:
        if not adjacency[node * n + neighbor]: continue
        if color[neighbor] == -1:
          color[neighbor] = 1 - color[node]
          stack[top] = neighbor
          inc top
        elif color[neighbor] == color[node]: return 0
  1
