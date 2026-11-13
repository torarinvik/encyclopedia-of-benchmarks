import std/[cstddef]

const
  NMax = 8
  MMax = 24
  InputMax = 4 + 3 * MMax + 1

proc isapDfs(u, sink: int, amount: int64, n: int,
    residual: var array[NMax, array[NMax, int64]],
    distance: array[NMax, int64], gap: var array[NMax + 1, int64],
    current: var array[NMax, int], stopped: var bool): int64 =
  if u == sink: return amount
  while current[u] < n:
    let v = current[u]
    if residual[u][v] > 0 and distance[u] == distance[v] + 1:
      let sent = isapDfs(v, sink, min(amount, residual[u][v]), n, residual, distance, gap, current, stopped)
      if sent > 0:
        residual[u][v] -= sent
        residual[v][u] += sent
        return sent
      if stopped: return 0
    inc current[u]
  let old = distance[u]
  var best = int64(n)
  for v in 0 ..< n:
    if residual[u][v] > 0: best = min(best, distance[v])
  let replacement = min(int64(n), best + 1)
  dec gap[int(old)]
  distance[u] = replacement
  inc gap[int(replacement)]
  current[u] = 0
  if old < int64(n) and gap[int(old)] == 0: stopped = true
  0

proc isapMaxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "isap_maxflow".} =
  if input.isNil or length < 4 or length > InputMax: return -1
  let nv = input[0]
  let mv = input[1]
  let sv = input[2]
  let tv = input[3]
  if nv < 2 or nv > NMax or mv < 0 or mv > MMax or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv:
    return -1
  let n = int(nv)
  let m = int(mv)
  let source = int(sv)
  let sink = int(tv)
  if int(length) != 4 + 3 * m: return -1
  var residual: array[NMax, array[NMax, int64]]
  for e in 0 ..< m:
    let u = input[4 + 3 * e]
    let v = input[5 + 3 * e]
    let capacity = input[6 + 3 * e]
    if u < 0 or u >= nv or v < 0 or v >= nv or u == v or capacity < 0 or capacity > 100: return -1
    residual[int(u)][int(v)] += capacity
  var distance: array[NMax, int64]
  for v in 0 ..< n: distance[v] = int64(n)
  distance[sink] = 0
  var queue: array[NMax, int]
  var head = 0
  var tail = 1
  queue[0] = sink
  while head < tail:
    let v = queue[head]
    inc head
    for p in 0 ..< n:
      if distance[p] == int64(n) and residual[p][v] > 0:
        distance[p] = distance[v] + 1
        queue[tail] = p
        inc tail
  if distance[source] >= int64(n): return 0
  var gap: array[NMax + 1, int64]
  for v in 0 ..< n: inc gap[int(distance[v])]
  var current: array[NMax, int]
  var stopped = false
  var flow = 0'i64
  while distance[source] < int64(n) and not stopped:
    flow += isapDfs(source, sink, 2400, n, residual, distance, gap, current, stopped)
  flow
