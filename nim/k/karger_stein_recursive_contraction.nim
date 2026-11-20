## Independently authored draft; not compiled or run.
type Graph = object
  n, m, q: int
  left, right: array[32, int]
  tape: array[64, int64]
  position: int

proc root(parent: array[12, int], vertex: int): int =
  result = vertex
  while parent[result] != result: result = parent[result]

proc solve(graph: var Graph, parent: array[12, int], components: int): int =
  if components <= 6:
    var indices: array[12, int]
    var count = 0
    for i in 0 ..< graph.n:
      if parent[i] == i:
        indices[i] = count
        inc count
    var best = graph.m + 1
    for mask in 0 ..< ((1 shl (components - 1)) - 1):
      let side = (mask shl 1) or 1
      var cut = 0
      for e in 0 ..< graph.m:
        let a = indices[root(parent, graph.left[e])]
        let b = indices[root(parent, graph.right[e])]
        if ((side shr a) and 1) != ((side shr b) and 1): inc cut
      best = min(best, cut)
    return best
  const targets = [0, 0, 0, 0, 0, 0, 0, 6, 7, 8, 9, 9, 10]
  var best = graph.m + 1
  for branch in 0 ..< 2:
    var next = parent
    for step in targets[components] ..< components:
      var live = 0
      for e in 0 ..< graph.m:
        if root(next, graph.left[e]) != root(next, graph.right[e]): inc live
      if graph.position >= graph.q: return -1
      var rank = graph.tape[graph.position]
      inc graph.position
      if rank < 0 or rank >= int64(live): return -1
      for e in 0 ..< graph.m:
        let a = root(next, graph.left[e])
        let b = root(next, graph.right[e])
        if a == b: continue
        if rank == 0:
          next[b] = a
          break
        dec rank
    let value = solve(graph, next, targets[components])
    if value < 0: return -1
    best = min(best, value)
  best

proc karger_stein_recursive_contraction*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "karger_stein_recursive_contraction".} =
  if input == nil or length < 3 or length > 132: return -1
  if input[0] < 2 or input[0] > 12 or input[1] < 1 or input[1] > 32 or input[2] < 0 or input[2] > 64: return -1
  var graph: Graph
  graph.n = int(input[0]); graph.m = int(input[1]); graph.q = int(input[2])
  if length != csize_t(3 + 2 * graph.m + graph.q): return -1
  var parent: array[12, int]
  for i in 0 ..< 12: parent[i] = i
  for i in 0 ..< graph.m:
    let u = input[3+2*i]
    let v = input[4+2*i]
    if u < 0 or v < 0 or u >= int64(graph.n) or v >= int64(graph.n) or u == v: return -1
    graph.left[i] = int(u); graph.right[i] = int(v)
    let a = root(parent, int(u)); let b = root(parent, int(v))
    parent[b] = a
  let initial = root(parent, 0)
  for i in 1 ..< graph.n:
    if root(parent, i) != initial: return -1
  for i in 0 ..< 12: parent[i] = i
  for i in 0 ..< graph.q: graph.tape[i] = input[3+2*graph.m+i]
  let value = solve(graph, parent, graph.n)
  if value < 0 or graph.position != graph.q: return -1
  int64(value)
