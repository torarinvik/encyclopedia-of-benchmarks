const
  MaxN = 64
  MaxQ = 64
  MaxInput = 320
  MaxWeight = 1_000_000'i64
  Neg = -1_152_921_504_606_846_976'i64

type Matrix = array[2, array[2, int64]]

proc identity(): Matrix =
  result[0] = [0'i64, Neg]
  result[1] = [Neg, 0'i64]

proc multiply(a, b: Matrix): Matrix =
  for row in 0 ..< 2:
    for col in 0 ..< 2:
      result[row][col] = max(a[row][0] + b[0][col], a[row][1] + b[1][col])

proc findRoot(parent: var array[MaxN, int], vertex: int): int =
  result = vertex
  while parent[result] != result:
    parent[result] = parent[parent[result]]
    result = parent[result]

proc setMatrix(tree: var array[2 * MaxN, Matrix], position: int, value: Matrix) =
  var node = MaxN + position
  tree[node] = value
  node = node div 2
  while node > 0:
    tree[node] = multiply(tree[2 * node], tree[2 * node + 1])
    node = node div 2

proc query(tree: array[2 * MaxN, Matrix], left, right: int): Matrix =
  var l = MaxN + left
  var r = MaxN + right
  var before = identity()
  var after = identity()
  while l < r:
    if (l and 1) != 0:
      before = multiply(before, tree[l])
      inc l
    if (r and 1) != 0:
      dec r
      after = multiply(tree[r], after)
    l = l div 2
    r = r div 2
  result = multiply(before, after)

proc summary(tree: array[2 * MaxN, Matrix], position, tail: array[MaxN, int], head: int): array[2, int64] =
  let product = query(tree, position[head], position[tail[head]] + 1)
  result[0] = max(product[0][0], product[0][1])
  result[1] = max(product[1][0], product[1][1])

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dynamic_tree_maximum_weight_independent_set*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_tree_maximum_weight_independent_set".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nn = input[0]
  let qq = input[1]
  if nn < 1 or nn > MaxN or qq < 0 or qq > MaxQ: return -1
  let n = int(nn)
  let q = int(qq)
  let edgeEnd = 2 + n + 2 * (n - 1)
  if int(length) != edgeEnd + 2 * q: return -1

  var dsu: array[MaxN, int]
  var weights: array[MaxN, int64]
  var adjacency: array[MaxN * MaxN, bool]
  for u in 0 ..< n:
    dsu[u] = u
    weights[u] = input[2 + u]
    if weights[u] < 0 or weights[u] > MaxWeight: return -1
  for edge in 0 ..< n - 1:
    let offset = 2 + n + 2 * edge
    let uu = input[offset]
    let vv = input[offset + 1]
    if uu < 0 or uu >= nn or vv < 0 or vv >= nn or uu == vv: return -1
    let u = int(uu)
    let v = int(vv)
    let ru = findRoot(dsu, u)
    let rv = findRoot(dsu, v)
    if ru == rv: return -1
    dsu[ru] = rv
    adjacency[u * MaxN + v] = true
    adjacency[v * MaxN + u] = true
  let rootSet = findRoot(dsu, 0)
  for v in 1 ..< n:
    if findRoot(dsu, v) != rootSet: return -1

  var updateVertex: array[MaxQ, int]
  var updateWeight: array[MaxQ, int64]
  for i in 0 ..< q:
    let offset = edgeEnd + 2 * i
    let vertex = input[offset]
    let weight = input[offset + 1]
    if vertex < 0 or vertex >= nn or weight < 0 or weight > MaxWeight: return -1
    updateVertex[i] = int(vertex)
    updateWeight[i] = weight
  let outputBytes = 8 * q
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2

  var parent: array[MaxN, int]
  for v in 0 ..< n: parent[v] = -2
  parent[0] = -1
  var order: array[MaxN, int]
  order[0] = 0
  var orderCount = 1
  var cursor = 0
  while cursor < orderCount:
    let u = order[cursor]
    inc cursor
    for v in 0 ..< n:
      if adjacency[u * MaxN + v] and parent[v] == -2:
        parent[v] = u
        order[orderCount] = v
        inc orderCount

  var subtree: array[MaxN, int]
  var heavy: array[MaxN, int]
  var skip, take: array[MaxN, int64]
  for u in 0 ..< n:
    subtree[u] = 1
    heavy[u] = -1
    take[u] = weights[u]
  for index in countdown(n - 1, 1):
    let u = order[index]
    let p = parent[u]
    subtree[p] += subtree[u]
    if heavy[p] < 0 or subtree[u] > subtree[heavy[p]]: heavy[p] = u
    skip[p] += max(skip[u], take[u])
    take[p] += skip[u]

  var head, position, tail: array[MaxN, int]
  var stack: array[MaxN, int]
  stack[0] = 0
  var stackLen = 1
  var clock = 0
  while stackLen > 0:
    dec stackLen
    let h = stack[stackLen]
    var u = h
    while u >= 0:
      head[u] = h
      position[u] = clock
      inc clock
      tail[h] = u
      for v in 1 ..< n:
        if parent[v] == u and v != heavy[u]:
          stack[stackLen] = v
          inc stackLen
      u = heavy[u]

  var matrices: array[MaxN, Matrix]
  var segment: array[2 * MaxN, Matrix]
  for i in 0 ..< 2 * MaxN: segment[i] = identity()
  for u in 0 ..< n:
    var light0 = 0'i64
    var light1 = weights[u]
    for v in 1 ..< n:
      if parent[v] == u and v != heavy[u]:
        light0 += max(skip[v], take[v])
        light1 += skip[v]
    matrices[u][0] = [light0, light0]
    matrices[u][1] = [light1, Neg]
    segment[MaxN + position[u]] = matrices[u]
  for i in countdown(MaxN - 1, 1): segment[i] = multiply(segment[2 * i], segment[2 * i + 1])

  var staged: array[MaxQ, int64]
  for i in 0 ..< q:
    let vertex = updateVertex[i]
    var h = head[vertex]
    var oldState = summary(segment, position, tail, h)
    let delta = updateWeight[i] - weights[vertex]
    weights[vertex] = updateWeight[i]
    matrices[vertex][1][0] += delta
    setMatrix(segment, position[vertex], matrices[vertex])
    var newState = summary(segment, position, tail, h)
    while parent[h] != -1:
      let p = parent[h]
      let ph = head[p]
      let before = summary(segment, position, tail, ph)
      let delta0 = max(newState[0], newState[1]) - max(oldState[0], oldState[1])
      let delta1 = newState[0] - oldState[0]
      matrices[p][0][0] += delta0
      matrices[p][0][1] += delta0
      matrices[p][1][0] += delta1
      setMatrix(segment, position[p], matrices[p])
      oldState = before
      newState = summary(segment, position, tail, ph)
      h = ph
    let answer = summary(segment, position, tail, 0)
    staged[i] = max(answer[0], answer[1])
  for i in 0 ..< q: storeLe(output, 8 * i, staged[i])
  int64(outputBytes)
