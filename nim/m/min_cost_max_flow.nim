# Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
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

proc min_cost_max_flow*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "min_cost_max_flow".} =
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
  var edges: array[2 * MaxM, Edge]
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
  var potential: array[MaxN, int64]
  var totalFlow, totalCost: int64 = 0
  while totalFlow < flowLimit:
    var dist: array[MaxN, int64]
    var parent: array[MaxN, int]
    var used: array[MaxN, bool]
    for i in 0 ..< n:
      dist[i] = Inf
      parent[i] = -1
      used[i] = false
    dist[source] = 0
    for step in 0 ..< n:
      var chosen = -1
      for v in 0 ..< n:
        if not used[v] and dist[v] != Inf and (chosen < 0 or dist[v] < dist[chosen]): chosen = v
      if chosen < 0: break
      used[chosen] = true
      for e in 0 ..< 2*m:
        if edges[e].fromVertex != chosen or edges[e].capacity <= 0: continue
        let v = edges[e].toVertex
        let candidate = dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
        if not used[v] and candidate < dist[v]:
          dist[v] = candidate
          parent[v] = e
    if dist[sink] == Inf: break
    for v in 0 ..< n:
      if dist[v] != Inf: potential[v] += dist[v]
    var amount = flowLimit - totalFlow
    var vertex = sink
    while vertex != source:
      let e = parent[vertex]
      if e < 0: return -1
      amount = min(amount, edges[e].capacity)
      vertex = edges[e].fromVertex
    vertex = sink
    while vertex != source:
      let e = parent[vertex]
      edges[e].capacity -= amount
      edges[edges[e].reverseIndex].capacity += amount
      vertex = edges[e].fromVertex
    totalFlow += amount
    totalCost += amount * (potential[sink] - potential[source])
  let flowBits = uint64(totalFlow)
  let costBits = uint64(totalCost)
  for i in 0 ..< 8:
    output[i] = uint8(flowBits shr (8*i))
    output[8+i] = uint8(costBits shr (8*i))
  16
