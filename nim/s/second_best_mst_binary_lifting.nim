type TopPair = array[2, int64]

proc combine(a, b: TopPair): TopPair =
  result = [-1'i64, -1'i64]
  for value in [a[0], a[1], b[0], b[1]]:
    if value > result[0]:
      result[1] = result[0]
      result[0] = value
    elif value < result[0] and value > result[1]:
      result[1] = value

proc root(parent: var array[8, int], initial: int): int =
  result = initial
  while parent[result] != result:
    parent[result] = parent[parent[result]]
    result = parent[result]

proc second_best_mst_binary_lifting*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "second_best_mst_binary_lifting".} =
  if input == nil or length < 2 or length > 63: return -1
  let nv = input[0]
  let mv = input[1]
  if nv < 1 or nv > 8 or mv < nv - 1 or mv > 20 or length != csize_t(2 + 3 * mv): return -1
  let n = int(nv)
  let m = int(mv)
  var u, v, order: array[20, int]
  var weight: array[20, int64]
  var seen: array[8, array[8, bool]]
  for i in 0 ..< m:
    let a = input[2 + 3 * i]
    let b = input[3 + 3 * i]
    let w = input[4 + 3 * i]
    if a < 0 or a >= b or b >= nv or w < 0 or w > 1000000: return -1
    if seen[int(a)][int(b)]: return -1
    seen[int(a)][int(b)] = true
    u[i] = int(a)
    v[i] = int(b)
    weight[i] = w
    order[i] = i
  var sortIndex = 1
  while sortIndex < m:
    let edge = order[sortIndex]
    var j = sortIndex
    while j > 0 and weight[order[j - 1]] > weight[edge]:
      order[j] = order[j - 1]
      dec j
    order[j] = edge
    inc sortIndex
  var parent: array[8, int]
  var selected: array[20, bool]
  var tree: array[8, seq[(int, int64)]]
  for i in 0 ..< n: parent[i] = i
  var count = 0
  var total: int64 = 0
  for i in 0 ..< m:
    let edge = order[i]
    let a = root(parent, u[edge])
    let b = root(parent, v[edge])
    if a != b:
      parent[a] = b
      selected[edge] = true
      inc count
      total += weight[edge]
      tree[u[edge]].add((v[edge], weight[edge]))
      tree[v[edge]].add((u[edge], weight[edge]))
  if count != n - 1: return -1
  var up: array[4, array[8, int]]
  var best: array[4, array[8, TopPair]]
  var depth: array[8, int]
  for level in 0 ..< 4:
    for vertex in 0 ..< n: best[level][vertex] = [-1'i64, -1'i64]
  for vertex in 0 ..< n: depth[vertex] = -1
  depth[0] = 0
  var queue = @[0]
  var head = 0
  while head < queue.len:
    let vertex = queue[head]
    inc head
    for (neighbor, w) in tree[vertex]:
      if depth[neighbor] < 0:
        depth[neighbor] = depth[vertex] + 1
        up[0][neighbor] = vertex
        best[0][neighbor] = [w, -1'i64]
        queue.add(neighbor)
  for level in 1 ..< 4:
    for vertex in 0 ..< n:
      let mid = up[level - 1][vertex]
      up[level][vertex] = up[level - 1][mid]
      best[level][vertex] = combine(best[level - 1][vertex], best[level - 1][mid])
  var increase: int64 = -1
  for edge in 0 ..< m:
    if selected[edge]: continue
    var a = u[edge]
    var b = v[edge]
    if depth[a] < depth[b]: swap(a, b)
    var path: TopPair = [-1'i64, -1'i64]
    let difference = depth[a] - depth[b]
    for level in 0 ..< 4:
      if (difference and (1 shl level)) != 0:
        path = combine(path, best[level][a])
        a = up[level][a]
    if a != b:
      for level in countdown(3, 0):
        if up[level][a] != up[level][b]:
          path = combine(combine(path, best[level][a]), best[level][b])
          a = up[level][a]
          b = up[level][b]
      path = combine(combine(path, best[0][a]), best[0][b])
    let removed = if weight[edge] > path[0]: path[0] else: path[1]
    if removed >= 0 and removed < weight[edge]:
      let delta = weight[edge] - removed
      if increase < 0 or delta < increase: increase = delta
  if increase < 0: return 0
  return total + increase + 1
