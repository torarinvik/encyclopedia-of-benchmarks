const MaxN = 8
const MaxM = 28
const MaxOut = 1 + 2 * MaxN + MaxN * MaxN

proc ancestor(parent: array[MaxN, array[MaxN, int]], source, a, target: int): bool =
  var v = target
  while v >= 0:
    if v == a: return true
    if v == source: break
    v = parent[source][v]
  false

proc putI64(outp: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[pos + b] = uint8((bits shr (8 * b)) and 255)

proc hubLabelingGreedyOrder(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
                            {.cdecl, exportc: "hub_labeling_greedy_order".} =
  if input.isNil or length < 2 or length > csize_t(2 + 2 * MaxM): return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > MaxN or m0 < 0 or m0 > n0 * (n0 - 1) div 2 or length != csize_t(2 + 2 * m0): return -1
  let n = int(n0); let m = int(m0)
  var adj: array[MaxN, array[MaxN, bool]]
  var prevU: int64 = -1; var prevV: int64 = -1
  for e in 0 ..< m:
    let u = input[2 + 2 * e]; let v = input[3 + 2 * e]
    if u < 0 or v <= u or v >= n0 or (e > 0 and (u < prevU or (u == prevU and v <= prevV))): return -1
    adj[int(u)][int(v)] = true; adj[int(v)][int(u)] = true; prevU = u; prevV = v
  var parent, depth: array[MaxN, array[MaxN, int]]
  var ways: array[MaxN, array[MaxN, int]]
  for s in 0 ..< n:
    for v in 0 ..< n: parent[s][v] = -1; depth[s][v] = -1; ways[s][v] = 0
    var queue: array[MaxN, int]
    var head = 0; var tail = 0
    queue[tail] = s; inc tail; depth[s][s] = 0; ways[s][s] = 1
    while head < tail:
      let u = queue[head]; inc head
      for v in 0 ..< n:
        if adj[u][v]:
          if depth[s][v] < 0:
            depth[s][v] = depth[s][u] + 1; parent[s][v] = u; ways[s][v] = ways[s][u]
            queue[tail] = v; inc tail
          elif depth[s][v] == depth[s][u] + 1:
            ways[s][v] = min(2, ways[s][v] + ways[s][u])
    for v in 0 ..< n:
      if depth[s][v] < 0 or ways[s][v] != 1: return -1
  var active: array[MaxN, array[MaxN, bool]]
  for s in 0 ..< n:
    for t in 0 ..< n: active[s][t] = true
  var order, rank: array[MaxN, int]
  for turn in 0 ..< n:
    var counts: array[MaxN, int]
    for s in 0 ..< n:
      for t in 0 ..< n:
        if active[s][t]:
          var v = t
          while v >= 0:
            inc counts[v]
            if v == s: break
            v = parent[s][v]
    var best = 0
    for v in 1 ..< n:
      if counts[v] > counts[best]: best = v
    order[turn] = best; rank[best] = turn
    for s in 0 ..< n:
      for t in 0 ..< n:
        if active[s][t] and ancestor(parent, s, best, t): active[s][t] = false
  var has: array[MaxN, array[MaxN, bool]]
  var labelDist: array[MaxN, array[MaxN, int]]
  for u in 0 ..< n:
    for v in u ..< n:
      var path: array[MaxN, int]; var pathLen = 0; var x = v
      while x >= 0:
        path[pathLen] = x; inc pathLen
        if x == u: break
        x = parent[u][x]
      if x < 0: return -1
      var hub = path[0]
      for i in 1 ..< pathLen:
        if rank[path[i]] < rank[hub]: hub = path[i]
      has[u][hub] = true; has[v][hub] = true
      labelDist[u][hub] = depth[u][hub]; labelDist[v][hub] = depth[v][hub]
  var staged: array[MaxOut, int64]
  var used = 0
  staged[used] = int64(n); inc used
  for i in 0 ..< n: staged[used] = int64(order[i]); inc used
  for v in 0 ..< n:
    var count = 0
    for h in 0 ..< n: if has[v][h]: inc count
    staged[used] = int64(count); inc used
    for h in 0 ..< n:
      if has[v][h]: staged[used] = int64(h or (labelDist[v][h] shl 8)); inc used
  let required = used * 8
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< used: putI64(output, i * 8, staged[i])
  int64(required)
