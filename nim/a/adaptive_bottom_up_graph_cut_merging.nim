const MaxN = 8
const MaxM = 16
const MaxB = 4
const Stride = 10

proc allowedArc(u, v, n: int; allowed: array[MaxN, bool]): bool =
  if u < n and not allowed[u]: return false
  if v < n and not allowed[v]: return false
  return v != n and u != n + 1

proc augment(residual: var array[Stride * Stride, int64]; n: int;
             allowed: array[MaxN, bool]) =
  let source = n
  let sink = n + 1
  while true:
    var parent: array[Stride, int]
    var queue: array[Stride, int]
    for i in 0 ..< Stride: parent[i] = -1
    parent[source] = source
    var head = 0
    var tail = 0
    queue[tail] = source
    inc tail
    while head < tail and parent[sink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< n + 2:
        if parent[v] < 0 and residual[u * Stride + v] > 0 and allowedArc(u, v, n, allowed):
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == sink: break
    if parent[sink] < 0: return
    var amount = int64(n * 7)
    var v = sink
    while v != source:
      let u = parent[v]
      amount = min(amount, residual[u * Stride + v])
      v = u
    v = sink
    while v != source:
      let u = parent[v]
      residual[u * Stride + v] -= amount
      residual[v * Stride + u] += amount
      v = u

proc adaptive_bottom_up_graph_cut_merging*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "adaptive_bottom_up_graph_cut_merging".} =
  if input.isNil or length < 3 or length > csize_t(92): return -1
  let rawN = input[0]
  let rawM = input[1]
  let rawB = input[2]
  if rawN < 2 or rawN > MaxN or rawM < 0 or rawM > MaxM or rawB < 1 or rawB > MaxB or rawB > rawN or
      length != csize_t(3 + 3 * rawN + 4 * rawM): return -1
  let n = int(rawN)
  let m = int(rawM)
  let blockCount = int(rawB)
  var at = 3
  var block: array[MaxN, int]
  var seen: array[MaxB, bool]
  for u in 0 ..< n:
    let x = input[at]
    inc at
    if x < 0 or x >= rawB: return -1
    block[u] = int(x)
    seen[block[u]] = true
  for b in 0 ..< blockCount:
    if not seen[b]: return -1
  var sourceCap, sinkCap: array[MaxN, int64]
  for u in 0 ..< n:
    sourceCap[u] = input[at]
    inc at
    if sourceCap[u] < 0 or sourceCap[u] > 7: return -1
  for u in 0 ..< n:
    sinkCap[u] = input[at]
    inc at
    if sinkCap[u] < 0 or sinkCap[u] > 7: return -1

  var eu, ev, ba, bb: array[MaxM, int]
  var uv, vu: array[MaxM, int64]
  var cross, enabled: array[MaxM, bool]
  var residual: array[Stride * Stride, int64]
  for u in 0 ..< n:
    residual[n * Stride + u] += sourceCap[u]
    residual[u * Stride + n + 1] += sinkCap[u]
  var potential: array[MaxB * MaxB, int64]
  var present: array[MaxB * MaxB, bool]
  for i in 0 ..< m:
    let ru = input[at]
    let rv = input[at + 1]
    let c = input[at + 2]
    let d = input[at + 3]
    at += 4
    if ru < 0 or ru >= rawN or rv < 0 or rv >= rawN or ru == rv or c < 0 or c > 7 or d < 0 or d > 7: return -1
    let u = int(ru)
    let v = int(rv)
    eu[i] = u; ev[i] = v; uv[i] = c; vu[i] = d
    if block[u] == block[v]:
      residual[u * Stride + v] += c
      residual[v * Stride + u] += d
    else:
      ba[i] = min(block[u], block[v]); bb[i] = max(block[u], block[v])
      cross[i] = c != 0 or d != 0
      if cross[i]: present[ba[i] * MaxB + bb[i]] = true

  var allowed: array[MaxN, bool]
  for b in 0 ..< blockCount:
    for u in 0 ..< n: allowed[u] = block[u] == b
    augment(residual, n, allowed)

  var tag: array[MaxN, int]
  for b in 0 ..< blockCount:
    for u in 0 ..< n: allowed[u] = block[u] == b
    var ss, tt: array[Stride, bool]
    var queue: array[Stride, int]
    var head = 0
    var tail = 0
    ss[n] = true; queue[tail] = n; inc tail
    while head < tail:
      let u = queue[head]; inc head
      for v in 0 ..< n + 2:
        if not ss[v] and residual[u * Stride + v] > 0 and (u >= n or allowed[u]) and (v >= n or allowed[v]):
          ss[v] = true; queue[tail] = v; inc tail
    head = 0; tail = 0
    tt[n + 1] = true; queue[tail] = n + 1; inc tail
    while head < tail:
      let v = queue[head]; inc head
      for u in 0 ..< n + 2:
        if not tt[u] and residual[u * Stride + v] > 0 and (u >= n or allowed[u]) and (v >= n or allowed[v]):
          tt[u] = true; queue[tail] = u; inc tail
    for u in 0 ..< n:
      if allowed[u]: tag[u] = if ss[u]: 1 elif tt[u]: 2 else: 0

  for i in 0 ..< m:
    if cross[i] and tag[eu[i]] != tag[ev[i]]:
      potential[ba[i] * MaxB + bb[i]] += (if uv[i] > 0: 1'i64 else: 0'i64) + (if vu[i] > 0: 1'i64 else: 0'i64)
  var orderA, orderB: array[MaxB * MaxB, int]
  var orderN = 0
  for a in 0 ..< blockCount:
    for b in a + 1 ..< blockCount:
      if present[a * MaxB + b]:
        var p = orderN; inc orderN
        while p > 0:
          let pa = orderA[p - 1]; let pb = orderB[p - 1]
          if potential[pa * MaxB + pb] > potential[a * MaxB + b] or
              (potential[pa * MaxB + pb] == potential[a * MaxB + b] and (pa < a or (pa == a and pb <= b))): break
          orderA[p] = pa; orderB[p] = pb; dec p
        orderA[p] = a; orderB[p] = b
  var parent: array[MaxB, int]
  for b in 0 ..< blockCount: parent[b] = b
  for oi in 0 ..< orderN:
    var a = orderA[oi]; var b = orderB[oi]
    while parent[a] != a: a = parent[a]
    while parent[b] != b: b = parent[b]
    if a == b: continue
    let root = min(a, b); let other = max(a, b); parent[other] = root
    for i in 0 ..< m:
      if cross[i] and not enabled[i]:
        var x = ba[i]; var y = bb[i]
        while parent[x] != x: x = parent[x]
        while parent[y] != y: y = parent[y]
        if x == y:
          residual[eu[i] * Stride + ev[i]] += uv[i]
          residual[ev[i] * Stride + eu[i]] += vu[i]
          enabled[i] = true
    for u in 0 ..< n:
      var x = block[u]
      while parent[x] != x: x = parent[x]
      allowed[u] = x == root
    augment(residual, n, allowed)

  var flow = 0'i64
  for u in 0 ..< n: flow += sourceCap[u] - residual[n * Stride + u]
  return flow
