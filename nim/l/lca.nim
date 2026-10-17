const MaxNodes = 64

proc findRoot(parent: var array[MaxNodes, int], vertex: int): int =
  var v = vertex
  while parent[v] != v:
    parent[v] = parent[parent[v]]
    v = parent[v]
  v

proc lca*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lca".} =
  if input == nil or length < 3 or length > 129: return -1
  if input[0] < 1 or input[0] > int64(MaxNodes): return -1
  let n = int(input[0])
  if int(length) != 2 * n + 1: return -1
  var dsu: array[MaxNodes, int]
  var degree: array[MaxNodes, int]
  var adjacency: array[MaxNodes, array[MaxNodes, int]]
  for i in 0 ..< n: dsu[i] = i
  var position = 1
  for _ in 0 ..< n - 1:
    let uArg = input[position]
    let vArg = input[position + 1]
    position += 2
    if uArg < 0 or uArg >= n or vArg < 0 or vArg >= n or uArg == vArg: return -1
    let u = int(uArg)
    let v = int(vArg)
    let ru = findRoot(dsu, u)
    let rv = findRoot(dsu, v)
    if ru == rv: return -1
    dsu[ru] = rv
    adjacency[u][degree[u]] = v
    inc degree[u]
    adjacency[v][degree[v]] = u
    inc degree[v]
  let qaArg = input[position]
  let qbArg = input[position + 1]
  if qaArg < 0 or qaArg >= n or qbArg < 0 or qbArg >= n: return -1
  let component = findRoot(dsu, 0)
  for i in 1 ..< n:
    if findRoot(dsu, i) != component: return -1

  var parent: array[MaxNodes, int]
  var depth: array[MaxNodes, int]
  var stack: array[MaxNodes, int]
  var seen: array[MaxNodes, bool]
  var stackSize = 1
  stack[0] = 0
  seen[0] = true
  while stackSize > 0:
    dec stackSize
    let vertex = stack[stackSize]
    for i in 0 ..< degree[vertex]:
      let next = adjacency[vertex][i]
      if not seen[next]:
        seen[next] = true
        parent[next] = vertex
        depth[next] = depth[vertex] + 1
        stack[stackSize] = next
        inc stackSize
  var a = int(qaArg)
  var b = int(qbArg)
  if depth[a] < depth[b]: swap(a, b)
  while depth[a] != depth[b]: a = parent[a]
  if a == b: return int64(a)
  while a != b:
    a = parent[a]
    b = parent[b]
  int64(a)
