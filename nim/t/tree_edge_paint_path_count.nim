const
  MaxN = 16
  MaxQ = 32
  MaxEdges = 15
  LogN = 5

proc rootOf(parent: var array[MaxN, int], nodeArg: int): int =
  var node = nodeArg
  while parent[node] != node:
    parent[node] = parent[parent[node]]
    node = parent[node]
  node

proc pointSet(tree: var array[64, int64], base, index: int, value: int64) =
  var position = base + index
  tree[position] = value
  position = position div 2
  while position > 0:
    tree[position] = tree[2 * position] + tree[2 * position + 1]
    position = position div 2

proc rangeSum(tree: array[64, int64], base, leftArg, rightArg: int): int64 =
  if leftArg > rightArg: return 0
  var l = base + leftArg
  var r = base + rightArg + 1
  var total = 0'i64
  while l < r:
    if (l and 1) == 1:
      total += tree[l]
      inc l
    if (r and 1) == 1:
      dec r
      total += tree[r]
    l = l div 2
    r = r div 2
  total

proc lca(aArg, bArg: int, depth, parent: array[MaxN, int], ancestor: array[LogN * MaxN, int]): int =
  var a = aArg
  var b = bArg
  if depth[a] < depth[b]: swap(a, b)
  var difference = depth[a] - depth[b]
  for bit in 0 ..< LogN:
    if ((difference shr bit) and 1) != 0: a = ancestor[bit * MaxN + a]
  if a == b: return a
  for bit in countdown(LogN - 1, 0):
    if ancestor[bit * MaxN + a] != ancestor[bit * MaxN + b]:
      a = ancestor[bit * MaxN + a]
      b = ancestor[bit * MaxN + b]
  parent[a]

proc tree_edge_paint_path_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_edge_paint_path_count".} =
  if input.isNil or length < csize_t(2) or length > csize_t(129): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > MaxN or q64 < 0 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  let m = n - 1
  if length != csize_t(2 + 2 * m + 3 * q): return -1

  var edgeU, edgeV: array[MaxEdges, int]
  var dsu: array[MaxN, int]
  for i in 0 ..< n: dsu[i] = i
  var cursor = 2
  for edge in 0 ..< m:
    let u64 = input[cursor]
    let v64 = input[cursor + 1]
    cursor += 2
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
    let u = int(u64)
    let v = int(v64)
    edgeU[edge] = u
    edgeV[edge] = v
    let ru = rootOf(dsu, u)
    let rv = rootOf(dsu, v)
    if ru == rv: return -1
    dsu[ru] = rv
  let treeRoot = rootOf(dsu, 0)
  for v in 1 ..< n:
    if rootOf(dsu, v) != treeRoot: return -1

  var parent, depth, first, visited: array[MaxN, int]
  var down, up: array[MaxEdges, int]
  var stackNode, stackParent, stackIncoming, stackCursor: array[MaxN, int]
  visited[0] = 1
  stackParent[0] = -1
  stackIncoming[0] = -1
  var top = 0
  var occurrences = 0
  while top >= 0:
    let node = stackNode[top]
    var found = false
    while stackCursor[top] < m:
      let edge = stackCursor[top]
      inc stackCursor[top]
      if edgeU[edge] != node and edgeV[edge] != node: continue
      let child = if edgeU[edge] == node: edgeV[edge] else: edgeU[edge]
      if child == stackParent[top]: continue
      if visited[child] != 0: return -1
      visited[child] = 1
      parent[child] = node
      depth[child] = depth[node] + 1
      down[edge] = occurrences
      inc occurrences
      first[child] = occurrences
      inc top
      stackNode[top] = child
      stackParent[top] = node
      stackIncoming[top] = edge
      stackCursor[top] = 0
      found = true
      break
    if not found:
      let incoming = stackIncoming[top]
      dec top
      if incoming >= 0:
        up[incoming] = occurrences
        inc occurrences

  var ancestor: array[LogN * MaxN, int]
  for v in 0 ..< n: ancestor[v] = parent[v]
  for k in 1 ..< LogN:
    for v in 0 ..< n: ancestor[k * MaxN + v] = ancestor[(k - 1) * MaxN + ancestor[(k - 1) * MaxN + v]]
  var base = 1
  while base < occurrences: base *= 2
  var forward, backward: array[64, int64]
  var painted: array[MaxEdges, int]
  var total = 0'i64
  for _ in 0 ..< q:
    let kind = input[cursor]
    let a64 = input[cursor + 1]
    let b64 = input[cursor + 2]
    cursor += 3
    if kind == 0:
      if a64 < 0 or a64 >= m or b64 != 0: return -1
      let edge = int(a64)
      if painted[edge] == 0:
        painted[edge] = 1
        pointSet(forward, base, down[edge], 1)
        pointSet(backward, base, up[edge], 1)
    elif kind == 1:
      if a64 < 0 or a64 >= n64 or b64 < 0 or b64 >= n64: return -1
      let common = lca(int(a64), int(b64), depth, parent, ancestor)
      let leftA = first[common]
      let rightA = first[int(a64)] - 1
      let leftB = first[common]
      let rightB = first[int(b64)] - 1
      total += rangeSum(forward, base, leftA, rightA) - rangeSum(backward, base, leftA, rightA)
      total += rangeSum(forward, base, leftB, rightB) - rangeSum(backward, base, leftB, rightB)
    else:
      return -1
  total
