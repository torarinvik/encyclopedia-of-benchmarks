const
  NMax = 8
  MMax = 12
  KMax = 4
  InputMax = 50

proc ardReaches(n: int; allowed: array[NMax, array[NMax, bool]];
                residual: array[NMax, array[NMax, int64]];
                start: int; target: array[NMax, bool]): bool =
  if target[start]: return true
  var seen: array[NMax, bool]
  var queue: array[NMax, int]
  var head = 0
  var tail = 0
  seen[start] = true
  queue[tail] = start
  inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if not seen[v] and allowed[u][v] and residual[u][v] > 0:
        if target[v]: return true
        seen[v] = true
        queue[tail] = v
        inc tail
  false

proc ardFindPath(n: int; inRegion: array[NMax, bool];
                 allowed: array[NMax, array[NMax, bool]];
                 residual: array[NMax, array[NMax, int64]];
                 target: array[NMax, bool]; excess: array[NMax, int64];
                 parent: var array[NMax, int]): int =
  for v in 0 ..< NMax: parent[v] = -1
  var queue: array[NMax, int]
  var head = 0
  var tail = 0
  for v in 0 ..< n:
    if inRegion[v] and excess[v] > 0:
      parent[v] = v
      queue[tail] = v
      inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< n:
      if parent[v] >= 0 or not allowed[u][v] or residual[u][v] <= 0: continue
      parent[v] = u
      if target[v]: return v
      queue[tail] = v
      inc tail
  -1

proc ardDischarge(n, regionId, source, sink, boundaryCount: int;
                  regions: array[NMax, int];
                  boundaryByRegion: array[KMax, array[NMax, bool]];
                  residual: var array[NMax, array[NMax, int64]];
                  excess: var array[NMax, int64]; labels: var array[NMax, int];
                  flowValue: int64): int64 =
  var inRegion, external, insideTerminal: array[NMax, bool]
  for v in 0 ..< n:
    inRegion[v] = v != source and v != sink and regions[v] == regionId
    external[v] = boundaryByRegion[regionId][v]
    insideTerminal[v] = inRegion[v] or v == source or v == sink
  var allowed: array[NMax, array[NMax, bool]]
  var local: array[NMax, array[NMax, int64]]
  for u in 0 ..< n:
    for v in 0 ..< n:
      allowed[u][v] = (insideTerminal[u] and insideTerminal[v]) or
        (inRegion[u] and external[v]) or (external[u] and inRegion[v])
      if allowed[u][v] and not (external[u] and inRegion[v]): local[u][v] = residual[u][v]
  var flow = flowValue
  for stage in 0 .. boundaryCount:
    var target: array[NMax, bool]
    target[sink] = true
    for v in 0 ..< n:
      if external[v] and labels[v] < stage: target[v] = true
    while true:
      var parent: array[NMax, int]
      let finish = ardFindPath(n, inRegion, allowed, local, target, excess, parent)
      if finish < 0: break
      var path: array[NMax, int]
      var pathLen = 0
      var v = finish
      while true:
        path[pathLen] = v
        inc pathLen
        if parent[v] == v: break
        v = parent[v]
      let start = path[pathLen - 1]
      var amount = excess[start]
      var i = pathLen - 1
      while i > 0:
        let u = path[i]
        let v = path[i - 1]
        amount = min(amount, local[u][v])
        dec i
      i = pathLen - 1
      while i > 0:
        let u = path[i]
        let v = path[i - 1]
        local[u][v] -= amount
        local[v][u] += amount
        residual[u][v] -= amount
        residual[v][u] += amount
        dec i
      excess[start] -= amount
      if finish == sink: flow += amount
      else: excess[finish] += amount
  for u in 0 ..< n:
    if inRegion[u]:
      var nextLabel = boundaryCount
      for stage in 0 .. boundaryCount:
        var target: array[NMax, bool]
        target[sink] = true
        for v in 0 ..< n:
          if external[v] and labels[v] < stage: target[v] = true
        if ardReaches(n, allowed, local, u, target):
          nextLabel = stage
          break
      labels[u] = max(labels[u], nextLabel)
  flow

proc region_discharge_path_push_relabel_maxflow*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "region_discharge_path_push_relabel_maxflow".} =
  if input.isNil or length < 5 or length > csize_t(InputMax): return -1
  let rawN, rawM, rawK = input[0], input[1], input[2]
  let rawSource, rawSink = input[3], input[4]
  if rawN < 4 or rawN > NMax or rawM < 1 or rawM > MMax or rawK < 2 or rawK > KMax or
      rawK > rawN - 2 or rawSource < 0 or rawSource >= rawN or rawSink < 0 or rawSink >= rawN or
      rawSource == rawSink or length != csize_t(5 + rawN + 3 * rawM): return -1
  let n, m, k = int(rawN), int(rawM), int(rawK)
  let source, sink = int(rawSource), int(rawSink)
  var regions: array[NMax, int]
  var seen: array[KMax, bool]
  var capacity, residual: array[NMax, array[NMax, int64]]
  var boundaryByRegion: array[KMax, array[NMax, bool]]
  var boundary: array[NMax, bool]
  for v in 0 ..< n:
    let raw = input[5 + v]
    if v == source or v == sink:
      if raw != -1: return -1
      regions[v] = -1
    else:
      if raw < 0 or raw >= rawK: return -1
      regions[v] = int(raw)
      seen[regions[v]] = true
  for b in 0 ..< k:
    if not seen[b]: return -1
  for e in 0 ..< m:
    let p = 5 + n + 3 * e
    let ru, rv, cap = input[p], input[p + 1], input[p + 2]
    if ru < 0 or ru >= rawN or rv < 0 or rv >= rawN or ru == rv or rv == rawSource or
        ru == rawSink or cap < 0 or cap > 7: return -1
    let u, v = int(ru), int(rv)
    capacity[u][v] += cap
    if cap > 0 and regions[u] >= 0 and regions[v] >= 0 and regions[u] != regions[v]:
      boundary[u] = true
      boundary[v] = true
      boundaryByRegion[regions[u]][v] = true
      boundaryByRegion[regions[v]][u] = true
  var boundaryCount = 0
  for v in 0 ..< n:
    if boundary[v]: inc boundaryCount
  if boundaryCount < 2: return -1
  residual = capacity
  var excess: array[NMax, int64]
  var labels: array[NMax, int]
  var flow: int64 = 0
  for v in 0 ..< n:
    let amount = residual[source][v]
    if amount > 0:
      residual[source][v] = 0
      residual[v][source] += amount
      if v == sink: flow += amount
      else: excess[v] += amount
  labels[source] = boundaryCount
  for sweep in 0 ..< 2 * boundaryCount * boundaryCount + 1:
    for b in 0 ..< k:
      flow = ardDischarge(n, b, source, sink, boundaryCount, regions, boundaryByRegion,
                          residual, excess, labels, flow)
    var active = false
    for v in 0 ..< n:
      if v != source and v != sink and excess[v] > 0 and labels[v] < boundaryCount: active = true
    if not active: return flow
  -1

