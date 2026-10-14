## Heapsort packed undirected edges, then union their components by rank.
proc siftDown(keys: ptr UncheckedArray[int64], startRoot, limit: int) =
  var root = startRoot
  while root < limit div 2:
    var child = root * 2 + 1
    if child + 1 < limit and keys[child] < keys[child + 1]: inc child
    if keys[root] >= keys[child]: break
    swap(keys[root], keys[child])
    root = child
proc findRoot(parent: ptr UncheckedArray[csize_t], startNode: csize_t): csize_t =
  var node = startNode
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node
proc kruskal*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "kruskal".} =
  if values == nil or length < 2 or length > 12290: return -2
  if values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 4096: return -2
  let vertices = int(values[0]); let edges = int(values[1])
  if int(length) != 2 + 3 * edges or (vertices == 0 and edges != 0): return -2
  if vertices == 0: return 0
  var keys: array[4096, int64]
  for edge in 0 ..< edges:
    var u = values[2 + 3 * edge]; var v = values[3 + 3 * edge]; let weight = values[4 + 3 * edge]
    if u < 0 or v < 0 or u >= int64(vertices) or v >= int64(vertices) or weight < 0 or weight > 2147483647'i64: return -2
    if u > v: swap(u, v)
    keys[edge] = weight * 4096 + u * 64 + v
  for start in countdown(edges div 2 - 1, 0):
    if edges div 2 > 0: siftDown(cast[ptr UncheckedArray[int64]](addr keys[0]), start, edges)
  if edges > 1:
    for finish in countdown(edges - 1, 1):
      swap(keys[0], keys[finish])
      siftDown(cast[ptr UncheckedArray[int64]](addr keys[0]), 0, finish)
  var parent: array[64, csize_t]
  var ranks: array[64, csize_t]
  for vertex in 0 ..< vertices: parent[vertex] = csize_t(vertex)
  var selected = 0
  var total = 0'i64
  for edge in 0 ..< edges:
    if selected + 1 >= vertices: break
    let key = keys[edge]
    let u = csize_t((key mod 4096) div 64)
    let v = csize_t(key mod 64)
    let rootU = findRoot(cast[ptr UncheckedArray[csize_t]](addr parent[0]), u)
    let rootV = findRoot(cast[ptr UncheckedArray[csize_t]](addr parent[0]), v)
    if rootU != rootV:
      total += key div 4096
      inc selected
      if ranks[rootU] < ranks[rootV]: parent[rootU] = rootV
      elif ranks[rootU] > ranks[rootV]: parent[rootV] = rootU
      else:
        parent[rootV] = rootU
        inc ranks[rootU]
  if selected + 1 == vertices: return total
  -1
