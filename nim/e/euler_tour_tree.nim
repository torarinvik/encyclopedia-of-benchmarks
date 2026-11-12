const
  N = 8
  M = 32
  Nodes = N + 2 * M
  InputMax = 2 + N + 3 * M

type
  EttOp = object
    kind, a, b: int64
  EttTree = object
    left, right, parent, vertex, size, count: array[Nodes, int]
    value, total: array[Nodes, int64]
    priority: array[Nodes, uint64]
    edgeU, edgeV, arcUV, arcVU: array[M, int]
    active: array[M, bool]
    nextNode, edgeCount: int

proc mix(x0: uint64): uint64 =
  var x = x0 +% 0x9e3779b97f4a7c15'u64
  x = (x xor (x shr 30)) *% 0xbf58476d1ce4e5b9'u64
  x = (x xor (x shr 27)) *% 0x94d049bb133111eb'u64
  x xor (x shr 31)

proc nodeSize(tree: EttTree, node: int): int =
  if node < 0: 0 else: tree.size[node]
proc nodeCount(tree: EttTree, node: int): int =
  if node < 0: 0 else: tree.count[node]
proc nodeTotal(tree: EttTree, node: int): int64 =
  if node < 0: 0 else: tree.total[node]

proc pull(tree: var EttTree, node: int) =
  if node < 0: return
  tree.size[node] = 1 + nodeSize(tree, tree.left[node]) + nodeSize(tree, tree.right[node])
  tree.count[node] = (if tree.vertex[node] >= 0: 1 else: 0) + nodeCount(tree, tree.left[node]) + nodeCount(tree, tree.right[node])
  tree.total[node] = tree.value[node] + nodeTotal(tree, tree.left[node]) + nodeTotal(tree, tree.right[node])

proc merge(tree: var EttTree, a, b: int): int =
  if a < 0:
    if b >= 0: tree.parent[b] = -1
    return b
  if b < 0:
    tree.parent[a] = -1
    return a
  if tree.priority[a] > tree.priority[b]:
    let child = merge(tree, tree.right[a], b)
    tree.right[a] = child
    if child >= 0: tree.parent[child] = a
    pull(tree, a)
    tree.parent[a] = -1
    return a
  let child = merge(tree, a, tree.left[b])
  tree.left[b] = child
  if child >= 0: tree.parent[child] = b
  pull(tree, b)
  tree.parent[b] = -1
  return b

proc split(tree: var EttTree, root, prefix: int): tuple[first, rest: int] =
  if root < 0: return (-1, -1)
  if prefix <= nodeSize(tree, tree.left[root]):
    let (first, rest) = split(tree, tree.left[root], prefix)
    tree.left[root] = rest
    if rest >= 0: tree.parent[rest] = root
    pull(tree, root)
    tree.parent[root] = -1
    if first >= 0: tree.parent[first] = -1
    return (first, root)
  let leftSize = nodeSize(tree, tree.left[root])
  let (first, rest) = split(tree, tree.right[root], prefix - leftSize - 1)
  tree.right[root] = first
  if first >= 0: tree.parent[first] = root
  pull(tree, root)
  tree.parent[root] = -1
  if rest >= 0: tree.parent[rest] = -1
  (root, rest)

proc rootOf(tree: EttTree, node0: int): int =
  var node = node0
  while tree.parent[node] >= 0: node = tree.parent[node]
  node

proc position(tree: EttTree, node0: int): int =
  var node = node0
  var result = nodeSize(tree, tree.left[node])
  while tree.parent[node] >= 0:
    let parent = tree.parent[node]
    if tree.right[parent] == node: result += 1 + nodeSize(tree, tree.left[parent])
    node = parent
  result

proc rotate(tree: var EttTree, root, node: int): int =
  let (first, rest) = split(tree, root, position(tree, node))
  merge(tree, rest, first)

proc reachable(adjacency: array[N, array[N, bool]], start, target, n: int): bool =
  var seen: array[N, bool]
  var stack: array[N, int]
  var top = 1
  stack[0] = start
  seen[start] = true
  while top > 0:
    dec top
    let u = stack[top]
    if u == target: return true
    for v in 0 ..< n:
      if adjacency[u][v] and not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  false

proc initialize(tree: var EttTree, weights: array[N, int64], n: int) =
  for i in 0 ..< Nodes:
    tree.left[i] = -1; tree.right[i] = -1; tree.parent[i] = -1; tree.vertex[i] = -1
    tree.priority[i] = mix(uint64(i))
  for i in 0 ..< n:
    tree.vertex[i] = i; tree.value[i] = weights[i]; tree.total[i] = weights[i]
    tree.size[i] = 1; tree.count[i] = 1
  tree.nextNode = n
  tree.edgeCount = 0

proc link(tree: var EttTree, u, v: int) =
  let a = rotate(tree, rootOf(tree, u), u)
  let b = rotate(tree, rootOf(tree, v), v)
  let uv = tree.nextNode
  let vu = uv + 1
  tree.nextNode += 2
  for node in [uv, vu]:
    tree.left[node] = -1; tree.right[node] = -1; tree.parent[node] = -1
    tree.vertex[node] = -1; tree.value[node] = 0; tree.total[node] = 0
    tree.size[node] = 1; tree.count[node] = 0
  let root = merge(tree, merge(tree, merge(tree, a, uv), b), vu)
  tree.parent[root] = -1
  let e = tree.edgeCount
  inc tree.edgeCount
  tree.edgeU[e] = u; tree.edgeV[e] = v; tree.arcUV[e] = uv; tree.arcVU[e] = vu; tree.active[e] = true

proc cut(tree: var EttTree, u, v: int) =
  var edge = -1
  if tree.edgeCount > 0:
    for offset in countdown(tree.edgeCount - 1, 0):
      if tree.active[offset] and ((tree.edgeU[offset] == u and tree.edgeV[offset] == v) or (tree.edgeU[offset] == v and tree.edgeV[offset] == u)):
        edge = offset
        break
  let firstArc = if tree.edgeU[edge] == u and tree.edgeV[edge] == v: tree.arcUV[edge] else: tree.arcVU[edge]
  let secondArc = if firstArc == tree.arcUV[edge]: tree.arcVU[edge] else: tree.arcUV[edge]
  let root = rotate(tree, rootOf(tree, firstArc), firstArc)
  let (_, rest) = split(tree, root, 1)
  let (between, suffix) = split(tree, rest, position(tree, secondArc))
  let (_, other) = split(tree, suffix, 1)
  if between >= 0: tree.parent[between] = -1
  if other >= 0: tree.parent[other] = -1
  tree.active[edge] = false

proc setWeight(tree: var EttTree, vertex: int, value: int64) =
  tree.value[vertex] = value
  var path: array[Nodes, int]
  var count = 0
  var node = vertex
  while node >= 0:
    path[count] = node; inc count; node = tree.parent[node]
  for i in 0 ..< count: pull(tree, path[i])

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc euler_tour_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "euler_tour_tree".} =
  if input.isNil or length < 2 or length > csize_t(InputMax): return -1
  let nr = input[0]; let mr = input[1]
  if nr < 1 or nr > N.int64 or mr < 1 or mr > M.int64: return -1
  let n = int(nr); let m = int(mr); var cursor = 2
  var weights: array[N, int64]
  for i in 0 ..< n:
    if cursor >= int(length): return -1
    weights[i] = input[cursor]; inc cursor
    if weights[i] < -100 or weights[i] > 100: return -1
  var operations: array[M, EttOp]
  var queryCount = 0
  for i in 0 ..< m:
    if cursor >= int(length): return -1
    let kind = input[cursor]; inc cursor
    if kind == 0 or kind == 1:
      if cursor + 2 > int(length): return -1
      let u = input[cursor]; let v = input[cursor + 1]; cursor += 2
      if u < 0 or u >= nr or v < 0 or v >= nr or u == v: return -1
      operations[i] = EttOp(kind: kind, a: u, b: v)
    elif kind == 2:
      if cursor + 2 > int(length): return -1
      let vertex = input[cursor]; let value = input[cursor + 1]; cursor += 2
      if vertex < 0 or vertex >= nr or value < -100 or value > 100: return -1
      operations[i] = EttOp(kind: kind, a: vertex, b: value)
    elif kind == 3:
      if cursor >= int(length): return -1
      let vertex = input[cursor]; inc cursor
      if vertex < 0 or vertex >= nr: return -1
      operations[i] = EttOp(kind: kind, a: vertex, b: 0); inc queryCount
    else: return -1
  if cursor != int(length) or queryCount == 0: return -1
  var adjacency: array[N, array[N, bool]]
  for op in operations.toOpenArray(0, m - 1):
    let u = int(op.a); let v = int(op.b)
    if op.kind == 0:
      if reachable(adjacency, u, v, n): return -1
      adjacency[u][v] = true; adjacency[v][u] = true
    elif op.kind == 1:
      if not adjacency[u][v]: return -1
      adjacency[u][v] = false; adjacency[v][u] = false
  let required = 16 * queryCount
  if output.isNil or capacity < csize_t(required): return -2
  var tree: EttTree
  initialize(tree, weights, n)
  var answers: array[2 * M, int64]
  var answerCount = 0
  for op in operations.toOpenArray(0, m - 1):
    let a = int(op.a); let b = int(op.b)
    if op.kind == 0: link(tree, a, b)
    elif op.kind == 1: cut(tree, a, b)
    elif op.kind == 2: setWeight(tree, a, op.b)
    else:
      let root = rootOf(tree, a)
      answers[answerCount] = int64(tree.count[root])
      answers[answerCount + 1] = tree.total[root]
      answerCount += 2
  for i in 0 ..< answerCount: storeLe(output, 8 * i, answers[i])
  int64(required)
