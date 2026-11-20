const MaxN = 6
const MaxM = 10
const Stride = 8
const Offset = 7000'i64
const Scales: array[9, int64] = [0'i64, 2, 2, 6, 12, 60, 60, 420, 840]

proc member(owner, side: int64): bool = owner == side or owner == 2

proc solve(side: int64, n, m: int, owner: array[MaxN, int64],
    sourceCap, sinkCap: array[MaxN, int64], eu, ev: array[MaxM, int],
    uv, vu: array[MaxM, int64], lambda: array[MaxN, int64], scale: int64,
    labels: var array[MaxN, int64]): int64 =
  let source = n
  let sink = n + 1
  let size = n + 2
  var residual: array[Stride * Stride, int64]
  var constant = 0'i64
  var flow = 0'i64
  var sourceSum = 0'i64
  var lambdaSum = 0'i64
  for u in 0 ..< n:
    sourceSum += sourceCap[u]
    if member(owner[u], side):
      let factor = if owner[u] == 2: scale div 2 else: scale
      residual[source * Stride + u] += sourceCap[u] * factor
      residual[u * Stride + sink] += sinkCap[u] * factor
    if owner[u] == 2: lambdaSum += abs(lambda[u])
  for i in 0 ..< m:
    if member(owner[eu[i]], side) and member(owner[ev[i]], side):
      let factor = if owner[eu[i]] == 2 and owner[ev[i]] == 2: scale div 2 else: scale
      residual[eu[i] * Stride + ev[i]] += uv[i] * factor
      residual[ev[i] * Stride + eu[i]] += vu[i] * factor
  for u in 0 ..< n:
    if owner[u] == 2:
      let q = if side == 0: lambda[u] else: -lambda[u]
      if q >= 0: residual[source * Stride + u] += q
      else:
        residual[u * Stride + sink] += -q
        constant += q
  while true:
    var parent: array[Stride, int]
    var queue: array[Stride, int]
    for i in 0 ..< size: parent[i] = -1
    parent[source] = source
    var head = 0
    var tail = 1
    queue[0] = source
    while head < tail and parent[sink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< size:
        if parent[v] < 0 and residual[u * Stride + v] > 0:
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == sink: break
    if parent[sink] < 0:
      for u in 0 ..< n:
        labels[u] = if member(owner[u], side) and parent[u] < 0: 1'i64 else: 0'i64
      return flow + constant
    var amount = sourceSum * scale + lambdaSum + 1
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
    flow += amount

proc dual_decomposition_graph_cut_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dual_decomposition_graph_cut_maxflow".} =
  if input.isNil or length < 4 or length > csize_t(63): return -1
  let rn = input[0]
  let rm = input[1]
  let ro = input[2]
  let rt = input[3]
  if rn < 3 or rn > MaxN or rm < 0 or rm > MaxM or ro < 1 or ro > 3 or rt < 1 or rt > 8 or
      length != csize_t(4 + 3 * rn + 4 * rm): return -1
  let n = int(rn)
  let m = int(rm)
  let overlap = int(ro)
  let rounds = int(rt)
  var at = 4
  var owner: array[MaxN, int64]
  var counts: array[3, int]
  for u in 0 ..< n:
    let x = input[at]
    inc at
    if x < 0 or x > 2: return -1
    owner[u] = x
    inc counts[int(x)]
  if counts[0] == 0 or counts[1] == 0 or counts[2] != overlap: return -1
  var sourceCap, sinkCap: array[MaxN, int64]
  for u in 0 ..< n:
    sourceCap[u] = input[at]
    inc at
    if sourceCap[u] < 0 or sourceCap[u] > 6 or sourceCap[u] mod 2 != 0: return -1
  for u in 0 ..< n:
    sinkCap[u] = input[at]
    inc at
    if sinkCap[u] < 0 or sinkCap[u] > 6 or sinkCap[u] mod 2 != 0: return -1
  var eu, ev: array[MaxM, int]
  var uv, vu: array[MaxM, int64]
  for i in 0 ..< m:
    let ru = input[at]
    let rv = input[at + 1]
    let c = input[at + 2]
    let d = input[at + 3]
    at += 4
    if ru < 0 or ru >= rn or rv < 0 or rv >= rn or ru == rv or
        (owner[int(ru)] == 0 and owner[int(rv)] == 1) or (owner[int(ru)] == 1 and owner[int(rv)] == 0) or
        c < 0 or c > 6 or c mod 2 != 0 or d < 0 or d > 6 or d mod 2 != 0: return -1
    eu[i] = int(ru); ev[i] = int(rv); uv[i] = c; vu[i] = d
  let scale = Scales[rounds]
  var lambda: array[MaxN, int64]
  var labelsM, labelsN: array[MaxN, int64]
  var dualScaled = 0'i64
  var agreement = false
  for iteration in 1 .. rounds:
    let energyM = solve(0, n, m, owner, sourceCap, sinkCap, eu, ev, uv, vu, lambda, scale, labelsM)
    let energyN = solve(1, n, m, owner, sourceCap, sinkCap, eu, ev, uv, vu, lambda, scale, labelsN)
    dualScaled = energyM + energyN
    agreement = true
    for u in 0 ..< n:
      if owner[u] == 2 and labelsM[u] != labelsN[u]: agreement = false
    if agreement or iteration == rounds: break
    let step = scale div iteration
    for u in 0 ..< n:
      if owner[u] == 2: lambda[u] += step * (labelsM[u] - labelsN[u])
  return 2 * (dualScaled + Offset) + (if agreement: 1'i64 else: 0'i64)
