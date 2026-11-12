const
  Modulus = 998_244_353'i64
  MaxN = 8
  MaxQ = 12
  MaxInput = 93

type
  Affine = object
    multiplier, addend: int64
  LctNode = object
    child: array[2, int]
    parent: int
    reversed: bool
    value, forward, backward: Affine
  Query = object
    kind, a, b, c, d: int64

proc identity(): Affine = Affine(multiplier: 1, addend: 0)

proc compose(after, before: Affine): Affine =
  Affine(multiplier: after.multiplier * before.multiplier mod Modulus,
         addend: (after.multiplier * before.addend + after.addend) mod Modulus)

proc isAuxRoot(nodes: var array[MaxN, LctNode], x: int): bool =
  let p = nodes[x].parent
  p < 0 or (nodes[p].child[0] != x and nodes[p].child[1] != x)

proc pull(nodes: var array[MaxN, LctNode], x: int) =
  let lf = if nodes[x].child[0] < 0: identity() else: nodes[nodes[x].child[0]].forward
  let rf = if nodes[x].child[1] < 0: identity() else: nodes[nodes[x].child[1]].forward
  let lb = if nodes[x].child[0] < 0: identity() else: nodes[nodes[x].child[0]].backward
  let rb = if nodes[x].child[1] < 0: identity() else: nodes[nodes[x].child[1]].backward
  nodes[x].forward = compose(rf, compose(nodes[x].value, lf))
  nodes[x].backward = compose(lb, compose(nodes[x].value, rb))

proc reversePath(nodes: var array[MaxN, LctNode], x: int) =
  if x < 0: return
  swap(nodes[x].child[0], nodes[x].child[1])
  swap(nodes[x].forward, nodes[x].backward)
  nodes[x].reversed = not nodes[x].reversed

proc push(nodes: var array[MaxN, LctNode], x: int) =
  if not nodes[x].reversed: return
  reversePath(nodes, nodes[x].child[0])
  reversePath(nodes, nodes[x].child[1])
  nodes[x].reversed = false

proc rotate(nodes: var array[MaxN, LctNode], x: int) =
  let p = nodes[x].parent
  let g = nodes[p].parent
  let direction = ord(nodes[p].child[1] == x)
  let middle = nodes[x].child[direction xor 1]
  if not isAuxRoot(nodes, p):
    nodes[g].child[ord(nodes[g].child[1] == p)] = x
  nodes[x].parent = g
  nodes[x].child[direction xor 1] = p
  nodes[p].parent = x
  nodes[p].child[direction] = middle
  if middle >= 0: nodes[middle].parent = p
  pull(nodes, p)
  pull(nodes, x)

proc splay(nodes: var array[MaxN, LctNode], x: int) =
  var stack: array[MaxN, int]
  var count = 1
  var y = x
  stack[0] = y
  while not isAuxRoot(nodes, y):
    y = nodes[y].parent
    stack[count] = y
    inc count
  while count > 0:
    dec count
    push(nodes, stack[count])
  while not isAuxRoot(nodes, x):
    let p = nodes[x].parent
    if not isAuxRoot(nodes, p):
      let g = nodes[p].parent
      let zigzig = (nodes[p].child[0] == x) == (nodes[g].child[0] == p)
      rotate(nodes, if zigzig: p else: x)
    rotate(nodes, x)

proc access(nodes: var array[MaxN, LctNode], x: int) =
  var last = -1
  var y = x
  while y >= 0:
    splay(nodes, y)
    nodes[y].child[1] = last
    if last >= 0: nodes[last].parent = y
    pull(nodes, y)
    last = y
    y = nodes[y].parent
  splay(nodes, x)

proc makeRoot(nodes: var array[MaxN, LctNode], x: int) =
  access(nodes, x)
  reversePath(nodes, x)

proc findRoot(nodes: var array[MaxN, LctNode], xValue: int): int =
  var x = xValue
  access(nodes, x)
  push(nodes, x)
  while nodes[x].child[0] >= 0:
    x = nodes[x].child[0]
    push(nodes, x)
  splay(nodes, x)
  x

proc linkNodes(nodes: var array[MaxN, LctNode], u, v: int): bool =
  if u == v: return false
  makeRoot(nodes, u)
  if findRoot(nodes, v) == u: return false
  nodes[u].parent = v
  true

proc cutNodes(nodes: var array[MaxN, LctNode], u, v: int): bool =
  if u == v: return false
  makeRoot(nodes, u)
  access(nodes, v)
  if nodes[v].child[0] != u or nodes[u].child[1] >= 0: return false
  nodes[v].child[0] = -1
  nodes[u].parent = -1
  pull(nodes, v)
  true

proc setValue(nodes: var array[MaxN, LctNode], vertex: int, value: Affine) =
  access(nodes, vertex)
  nodes[vertex].value = value
  pull(nodes, vertex)

proc pathComposition(nodes: var array[MaxN, LctNode], u, v: int, result: var Affine): bool =
  makeRoot(nodes, u)
  if findRoot(nodes, v) != u: return false
  makeRoot(nodes, u)
  access(nodes, v)
  result = nodes[v].forward
  true

proc findDsu(parent: var array[MaxN, int], itemValue: int): int =
  var item = itemValue
  while parent[item] != item:
    parent[item] = parent[parent[item]]
    item = parent[item]
  item

proc connected(adjacency: array[MaxN * MaxN, bool], n, start, target: int): bool =
  var seen: array[MaxN, bool]
  var stack: array[MaxN, int]
  var top = 1
  seen[start] = true
  stack[0] = start
  while top > 0:
    dec top
    let u = stack[top]
    if u == target: return true
    for v in 0 ..< n:
      if adjacency[u * MaxN + v] and not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  false

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc dynamic_tree_vertex_set_path_composite*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "dynamic_tree_vertex_set_path_composite".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or qValue < 1 or qValue > MaxQ.int64: return -1
  let n = nValue.int
  let q = qValue.int
  if length < csize_t(2 + 2 * n + 2 * (n - 1) + 4 * q): return -1
  var values: array[MaxN, Affine]
  for i in 0 ..< n:
    let multiplier = input[2 + 2 * i]
    let addend = input[3 + 2 * i]
    if multiplier < 1 or multiplier >= Modulus or addend < 0 or addend >= Modulus: return -1
    values[i] = Affine(multiplier: multiplier, addend: addend)

  var adjacency: array[MaxN * MaxN, bool]
  var dsu: array[MaxN, int]
  var edgeU, edgeV: array[MaxN, int]
  for i in 0 ..< n: dsu[i] = i
  var cursor = 2 + 2 * n
  for edge in 0 ..< n - 1:
    let uValue = input[cursor]
    let vValue = input[cursor + 1]
    cursor += 2
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = uValue.int
    let v = vValue.int
    let rootU = findDsu(dsu, u)
    let rootV = findDsu(dsu, v)
    if rootU == rootV: return -1
    dsu[rootV] = rootU
    adjacency[u * MaxN + v] = true
    adjacency[v * MaxN + u] = true
    edgeU[edge] = u
    edgeV[edge] = v

  var queries: array[MaxQ, Query]
  var answerCount = 0
  for i in 0 ..< q:
    if cursor >= int(length): return -1
    var current = Query(kind: input[cursor], a: 0, b: 0, c: 0, d: 0)
    inc cursor
    if current.kind == 0:
      if int(length) - cursor < 4: return -1
      current.a = input[cursor]; inc cursor
      current.b = input[cursor]; inc cursor
      current.c = input[cursor]; inc cursor
      current.d = input[cursor]; inc cursor
      if current.a < 0 or current.a >= nValue or current.b < 0 or current.b >= nValue or
          current.c < 0 or current.c >= nValue or current.d < 0 or current.d >= nValue or
          current.a == current.b or current.c == current.d: return -1
      let u = current.a.int; let v = current.b.int
      let w = current.c.int; let x = current.d.int
      if not adjacency[u * MaxN + v]: return -1
      adjacency[u * MaxN + v] = false; adjacency[v * MaxN + u] = false
      if connected(adjacency, n, w, x): return -1
      adjacency[w * MaxN + x] = true; adjacency[x * MaxN + w] = true
    elif current.kind == 1:
      if int(length) - cursor < 3: return -1
      current.a = input[cursor]; inc cursor
      current.b = input[cursor]; inc cursor
      current.c = input[cursor]; inc cursor
      if current.a < 0 or current.a >= nValue or current.b < 1 or current.b >= Modulus or
          current.c < 0 or current.c >= Modulus: return -1
    elif current.kind == 2:
      if int(length) - cursor < 3: return -1
      current.a = input[cursor]; inc cursor
      current.b = input[cursor]; inc cursor
      current.c = input[cursor]; inc cursor
      if current.a < 0 or current.a >= nValue or current.b < 0 or current.b >= nValue or
          current.c < 0 or current.c >= Modulus: return -1
      inc answerCount
    else: return -1
    queries[i] = current
  if cursor != int(length): return -1
  let required = 8 * answerCount
  if output.isNil or capacity < csize_t(required): return -2

  var nodes: array[MaxN, LctNode]
  for i in 0 ..< n:
    nodes[i].child = [-1, -1]
    nodes[i].parent = -1
    nodes[i].value = values[i]
    nodes[i].forward = values[i]
    nodes[i].backward = values[i]
  for edge in 0 ..< n - 1:
    if not linkNodes(nodes, edgeU[edge], edgeV[edge]): return -1
  var answers: array[MaxQ, int64]
  var written = 0
  for current in queries[0 ..< q]:
    if current.kind == 0:
      if not cutNodes(nodes, current.a.int, current.b.int) or not linkNodes(nodes, current.c.int, current.d.int): return -1
    elif current.kind == 1:
      setValue(nodes, current.a.int, Affine(multiplier: current.b, addend: current.c))
    else:
      var combined = identity()
      if not pathComposition(nodes, current.a.int, current.b.int, combined): return -1
      answers[written] = (combined.multiplier * current.c + combined.addend) mod Modulus
      inc written
  for i in 0 ..< written: storeLe(output, 8 * i, answers[i])
  int64(required)
