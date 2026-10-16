type Reach = array[8, bool]
proc maxflow(cap: array[64, int64], n, source, sink: int): tuple[value: int64, reachable: Reach] =
  var residual = cap
  var total = 0'i64
  while true:
    var parent: array[8, int]
    for i in 0 ..< n: parent[i] = -1
    parent[source] = source
    var queue: array[8, int]
    var head = 0; var tail = 1; queue[0] = source
    while head < tail and parent[sink] < 0:
      let u = queue[head]; inc head
      for v in 0 ..< n:
        if residual[u*n+v] > 0 and parent[v] < 0:
          parent[v] = u
          if v == sink: break
          queue[tail] = v; inc tail
    if parent[sink] < 0: break
    var amount = high(int64); var v = sink
    while v != source:
      let u = parent[v]; amount = min(amount, residual[u*n+v]); v = u
    v = sink
    while v != source:
      let u = parent[v]; residual[u*n+v] -= amount; residual[v*n+u] += amount; v = u
    total += amount
  var reach: Reach
  var queue: array[8, int]
  var head = 0; var tail = 1; queue[0] = source; reach[source] = true
  while head < tail:
    let u = queue[head]; inc head
    for v in 0 ..< n:
      if not reach[v] and residual[u*n+v] > 0: reach[v] = true; queue[tail] = v; inc tail
  (total, reach)

proc gomory_hu_tree*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "gomory_hu_tree".} =
  if a == nil or length < 2 or length > 65: return -1
  let n64 = a[0]
  if n64 < 1 or n64 > 8 or length != csize_t(1+n64*n64): return -1
  let n = int(n64)
  var cap: array[64, int64]
  for i in 0 ..< n*n:
    if a[1+i] < 0 or a[1+i] > 1000: return -1
    cap[i] = a[1+i]
  for i in 0 ..< n:
    for j in 0 ..< n:
      if cap[i*n+j] != (if i == j: 0 else: cap[j*n+i]): return -1
  var parent: array[8, int]
  var weight: array[8, int64]
  for s in 1 ..< n:
    let t = parent[s]; let result = maxflow(cap,n,s,t); weight[s] = result.value
    for v in 0 ..< n:
      if v != s and parent[v] == t and result.reachable[v]: parent[v] = s
    if t != 0 and result.reachable[parent[t]]:
      parent[s] = parent[t]
      parent[t] = s
      weight[s] = weight[t]
      weight[t] = result.value
  var pair: array[64, int64]
  for source in 0 ..< n:
    var prev: array[8, int]
    for i in 0 ..< n: prev[i] = -2
    var queue: array[8, int]
    var head = 0; var tail = 1; queue[0] = source; prev[source] = -1
    while head < tail:
      let u = queue[head]; inc head
      for v in 0 ..< n:
        if v != u and ((v > 0 and parent[v] == u) or (u > 0 and parent[u] == v)) and prev[v] == -2:
          prev[v] = u; queue[tail] = v; inc tail
    for target in 0 ..< n:
      if target != source:
        var x = target; var minimum = high(int64)
        while x != source:
          let p = prev[x]; let edge = if x > 0 and parent[x] == p: x else: p
          minimum = min(minimum, weight[edge]); x = p
        pair[source*n+target] = minimum
  var h = 14695981039346656037'u64
  for i in 0 ..< n*n:
    var bits = cast[uint64](pair[i])
    for k in 0 ..< 8: h = (h xor (bits and 255'u64)) * 1099511628211'u64; bits = bits shr 8
  cast[int64](h)
