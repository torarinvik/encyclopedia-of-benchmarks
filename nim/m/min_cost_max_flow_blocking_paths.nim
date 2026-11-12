# Clean-room shortest-path tight-edge blocking-flow method; see package RIGHTS.md.
const MaxN = 8
const MaxM = 16
const MaxInput = 69
const Inf = 1'i64 shl 60

type Edge = object
  fromVertex: int
  toVertex: int
  reverseIndex: int
  capacity: int64
  cost: int64

proc sendTightLevelFlow(u, sink: int, limit: int64, edges: var array[32, Edge],
    arcCount: int, dist: array[8, int64], level: array[8, int], current: var array[8, int]): int64 =
  if u == sink: return limit
  while current[u] < arcCount:
    let e = current[u]
    if edges[e].fromVertex != u or edges[e].capacity <= 0:
      inc current[u]
      continue
    let v = edges[e].toVertex
    if dist[v] == Inf or dist[v] != dist[u] + edges[e].cost or level[v] != level[u] + 1:
      inc current[u]
      continue
    let amount = min(limit, edges[e].capacity)
    let sent = sendTightLevelFlow(v, sink, amount, edges, arcCount, dist, level, current)
    if sent > 0:
      let reverse = edges[e].reverseIndex
      edges[e].capacity -= sent
      edges[reverse].capacity += sent
      if edges[e].capacity == 0: inc current[u]
      return sent
    inc current[u]
  return 0

proc min_cost_max_flow_blocking_paths*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "min_cost_max_flow_blocking_paths".} =
  if input.isNil or inputLength < 5 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  let mValue = input[1]
  let sourceValue = input[2]
  let sinkValue = input[3]
  let flowLimit = input[4]
  if nValue < 2 or nValue > MaxN or mValue < 0 or mValue > MaxM or
      inputLength != (5 + 4 * mValue).csize_t: return -1
  if sourceValue < 0 or sourceValue >= nValue or sinkValue < 0 or sinkValue >= nValue or
      sourceValue == sinkValue or flowLimit < 0 or flowLimit > 16: return -1
  let n = int(nValue)
  let m = int(mValue)
  let source = int(sourceValue)
  let sink = int(sinkValue)
  var edges: array[32, Edge]
  for i in 0 ..< m:
    let u = input[5 + 4*i]
    let v = input[6 + 4*i]
    let cap = input[7 + 4*i]
    let cost = input[8 + 4*i]
    if u < 0 or u >= nValue or v < 0 or v >= nValue or cap < 0 or cap > 5 or cost < 0 or cost > 20: return -1
    let e = 2*i
    edges[e] = Edge(fromVertex: int(u), toVertex: int(v), reverseIndex: e+1, capacity: cap, cost: cost)
    edges[e+1] = Edge(fromVertex: int(v), toVertex: int(u), reverseIndex: e, capacity: 0, cost: -cost)
  if output.isNil or outputCapacity < 16: return -2
  var totalFlow, totalCost: int64 = 0
  while totalFlow < flowLimit:
    var dist: array[8, int64]
    var queue: array[8, int]
    var inQueue: array[8, bool]
    for i in 0 ..< n: dist[i] = Inf
    dist[source] = 0
    var head, tail, queued = 0
    queue[tail] = source
    tail = (tail + 1) mod n
    inc queued
    inQueue[source] = true
    while queued > 0:
      let u = queue[head]
      head = (head + 1) mod n
      dec queued
      inQueue[u] = false
      for e in 0 ..< 2*m:
        if edges[e].fromVertex != u or edges[e].capacity <= 0: continue
        let v = edges[e].toVertex
        let candidate = dist[u] + edges[e].cost
        if candidate < dist[v]:
          dist[v] = candidate
          if not inQueue[v]:
            queue[tail] = v
            tail = (tail + 1) mod n
            inc queued
            inQueue[v] = true
    if dist[sink] == Inf: break
    while totalFlow < flowLimit:
      var level: array[8, int]
      var breadth: array[8, int]
      var current: array[8, int]
      for i in 0 ..< n: level[i] = -1
      var first, last = 0
      level[source] = 0
      breadth[last] = source
      inc last
      while first < last:
        let u = breadth[first]
        inc first
        for e in 0 ..< 2*m:
          if edges[e].fromVertex != u or edges[e].capacity <= 0: continue
          let v = edges[e].toVertex
          if dist[v] == dist[u] + edges[e].cost and level[v] < 0:
            level[v] = level[u] + 1
            breadth[last] = v
            inc last
      if level[sink] < 0: break
      let amount = sendTightLevelFlow(source, sink, flowLimit - totalFlow,
        edges, 2*m, dist, level, current)
      if amount == 0: break
      totalFlow += amount
      totalCost += amount * dist[sink]
  let flowBits = uint64(totalFlow)
  let costBits = uint64(totalCost)
  for i in 0 ..< 8:
    output[i] = uint8(flowBits shr (8*i))
    output[8+i] = uint8(costBits shr (8*i))
  16
