const MaxN = 8
const MaxInput = 65

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset + b] = uint8((bits shr (b * 8)) and 255)

proc metric_tsp_tree_doubling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "metric_tsp_tree_doubling".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  if n64 < 1 or n64 > int64(MaxN) or int64(length) != 1 + n64*n64: return -1
  let n = int(n64)
  var d: array[MaxN, array[MaxN, int64]]
  for u in 0..<n:
    for v in 0..<n:
      let w = input[1 + u*n + v]
      if w < 0 or w > 10000 or (u == v and w != 0): return -1
      d[u][v] = w
  for u in 0..<n:
    for v in (u+1)..<n:
      if d[u][v] != d[v][u]: return -1
  for u in 0..<n:
    for v in 0..<n:
      for k in 0..<n:
        if d[u][v] > d[u][k] + d[k][v]: return -1
  let outputBytes = 8 * (n + 2)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var processed, tree: array[MaxN, array[MaxN, bool]]
  var parent: array[MaxN, int]
  for i in 0..<n: parent[i] = i
  var accepted = 0
  let edgeCount = n * (n - 1) div 2
  for _ in 0..<edgeCount:
    if accepted + 1 >= n: break
    var bu = 0
    var bv = 0
    var bw = high(int64)
    for u in 0..<n:
      for v in (u+1)..<n:
        if not processed[u][v] and d[u][v] < bw:
          bu = u; bv = v; bw = d[u][v]
    processed[bu][bv] = true
    var ru = bu
    var rv = bv
    while parent[ru] != ru: ru = parent[ru]
    while parent[rv] != rv: rv = parent[rv]
    if ru != rv:
      parent[rv] = ru
      tree[bu][bv] = true
      tree[bv][bu] = true
      inc accepted
  var stack, order: array[MaxN, int]
  var visited: array[MaxN, bool]
  var top = 1
  var count = 0
  stack[0] = 0
  while top > 0:
    dec top
    let v = stack[top]
    if not visited[v]:
      visited[v] = true
      order[count] = v
      inc count
      for rev in countdown(n - 1, 0):
        if tree[v][rev] and not visited[rev]:
          stack[top] = rev
          inc top
  var cost = 0'i64
  for i in 0..<(n-1): cost += d[order[i]][order[i+1]]
  cost += d[order[n-1]][0]
  storeI64LE(output, 0, cost)
  for i in 0..<n: storeI64LE(output, 8 * (i + 1), int64(order[i]))
  storeI64LE(output, 8 * (n + 1), 0)
  int64(outputBytes)
