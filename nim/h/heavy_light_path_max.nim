const MaxN = 64
const MaxQ = 128
type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc putI64Le(output: U8Output, slot: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[slot * 8 + byte] = uint8((bits shr (byte * 8)) and 255)

proc maxI64(left, right: int64): int64 =
  if left > right: return left
  right

proc rangeMax(tree: var array[MaxN * 2, int64], n, left, right: int): int64 =
  var l = left + n
  var r = right + n + 1
  var maximum = int64(int32.low)
  while l < r:
    if (l and 1) != 0:
      maximum = maxI64(maximum, tree[l])
      inc l
    if (r and 1) != 0:
      dec r
      maximum = maxI64(maximum, tree[r])
    l = l div 2
    r = r div 2
  maximum

proc pointSet(tree: var array[MaxN * 2, int64], n, position: int, value: int64) =
  var p = position + n
  tree[p] = value
  while p > 1:
    p = p div 2
    tree[p] = maxI64(tree[p * 2], tree[p * 2 + 1])

proc pathMax(tree: var array[MaxN * 2, int64], n: int,
    parent, depth, head, position: var array[MaxN, int], aValue, bValue: int): int64 =
  var a = aValue
  var b = bValue
  var maximum = int64(int32.low)
  while head[a] != head[b]:
    if depth[head[a]] < depth[head[b]]: swap(a, b)
    maximum = maxI64(maximum, rangeMax(tree, n, position[head[a]], position[a]))
    a = parent[head[a]]
  if depth[a] > depth[b]: swap(a, b)
  maxI64(maximum, rangeMax(tree, n, position[a], position[b]))

proc heavy_light_path_max*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "heavy_light_path_max".} =
  if input == nil or length < 2: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(3 * n + 3 * q): return -1

  var values: array[MaxN, int64]
  var cursor = 2
  for v in 0 ..< n:
    values[v] = input[cursor]
    if values[v] < -2_147_483_648 or values[v] > 2_147_483_647: return -1
    inc cursor
  var adjacency: array[MaxN * MaxN, int]
  var degree: array[MaxN, int]
  for edge in 0 ..< (n - 1):
    let uv = input[cursor]
    let vv = input[cursor + 1]
    cursor += 2
    if uv < 0 or uv >= nValue or vv < 0 or vv >= nValue or uv == vv: return -1
    let u = int(uv)
    let v = int(vv)
    for i in 0 ..< degree[u]:
      if adjacency[u * MaxN + i] == v: return -1
    adjacency[u * MaxN + degree[u]] = v
    inc degree[u]
    adjacency[v * MaxN + degree[v]] = u
    inc degree[v]

  var parent, depth, order, stack: array[MaxN, int]
  for v in 0 ..< n: parent[v] = -2
  parent[0] = -1
  var top = 1
  var orderCount = 0
  stack[0] = 0
  while top > 0:
    dec top
    let u = stack[top]
    order[orderCount] = u
    inc orderCount
    for i in 0 ..< degree[u]:
      let v = adjacency[u * MaxN + i]
      if v == parent[u]: continue
      if parent[v] != -2: return -1
      parent[v] = u
      depth[v] = depth[u] + 1
      stack[top] = v
      inc top
  if orderCount != n: return -1

  var subtree, heavy: array[MaxN, int]
  for v in 0 ..< n:
    subtree[v] = 1
    heavy[v] = -1
  for i in countdown(n - 1, 1):
    let v = order[i]
    let p = parent[v]
    subtree[p] += subtree[v]
    if heavy[p] < 0 or subtree[v] > subtree[heavy[p]]: heavy[p] = v

  var head, position, todoVertex, todoHead: array[MaxN, int]
  var base: array[MaxN, int64]
  top = 1
  var timer = 0
  todoVertex[0] = 0
  todoHead[0] = 0
  while top > 0:
    dec top
    var u = todoVertex[top]
    let chain = todoHead[top]
    while u >= 0:
      head[u] = chain
      position[u] = timer
      base[timer] = values[u]
      inc timer
      for i in 0 ..< degree[u]:
        let v = adjacency[u * MaxN + i]
        if parent[v] == u and v != heavy[u]:
          todoVertex[top] = v
          todoHead[top] = v
          inc top
      u = heavy[u]

  var segment: array[MaxN * 2, int64]
  for i in 0 ..< n: segment[n + i] = base[i]
  for i in countdown(n - 1, 1): segment[i] = maxI64(segment[i * 2], segment[i * 2 + 1])

  var results: array[MaxQ, int64]
  var resultCount = 0
  let operations = cursor
  for i in 0 ..< q:
    let op = input[operations + 3 * i]
    let a = input[operations + 3 * i + 1]
    let b = input[operations + 3 * i + 2]
    if op == 0:
      if a < 0 or a >= nValue or b < -2_147_483_648 or b > 2_147_483_647: return -1
      values[int(a)] = b
      pointSet(segment, n, position[int(a)], b)
    elif op == 1:
      if a < 0 or a >= nValue or b < 0 or b >= nValue: return -1
      results[resultCount] = pathMax(segment, n, parent, depth, head, position, int(a), int(b))
      inc resultCount
    else:
      return -1

  let outputBytes = resultCount * 8
  if outputBytes > 0 and (output == nil or outputCapacity < csize_t(outputBytes)): return -2
  for i in 0 ..< resultCount: putI64Le(output, i, results[i])
  int64(outputBytes)
