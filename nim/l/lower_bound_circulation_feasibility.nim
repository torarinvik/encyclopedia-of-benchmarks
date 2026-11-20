const
  MaxN = 6
  MaxM = 8
  MaxInputLength = 35
  NodeCap = 8

proc lower_bound_circulation_feasibility*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lower_bound_circulation_feasibility".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  let mArg = input[1]
  if nArg < 1 or nArg > MaxN or mArg < 0 or mArg > MaxM: return -1
  let n = int(nArg)
  let m = int(mArg)
  if length != csize_t(2 + 4 * m): return -1

  var residual: array[NodeCap * NodeCap, int64]
  var balance: array[MaxN, int64]
  for index in 0 ..< m:
    let offset = 2 + 4 * index
    let uArg = input[offset]
    let vArg = input[offset + 1]
    let lower = input[offset + 2]
    let upper = input[offset + 3]
    if uArg < 0 or uArg >= nArg or vArg < 0 or vArg >= nArg or
        lower < 0 or upper < lower or upper > 2:
      return -1
    let u = int(uArg)
    let v = int(vArg)
    residual[u * NodeCap + v] += upper - lower
    balance[u] -= lower
    balance[v] += lower

  let source = n
  let sink = n + 1
  let nodeCount = n + 2
  var demand = 0'i64
  for vertex in 0 ..< n:
    if balance[vertex] > 0:
      residual[source * NodeCap + vertex] += balance[vertex]
      demand += balance[vertex]
    elif balance[vertex] < 0:
      residual[vertex * NodeCap + sink] -= balance[vertex]

  var flow = 0'i64
  while flow < demand:
    var parent: array[NodeCap, int]
    for vertex in 0 ..< nodeCount: parent[vertex] = -1
    var queue: array[NodeCap, int]
    var head = 0
    var tail = 0
    parent[source] = source
    queue[tail] = source
    inc tail
    while head < tail and parent[sink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< nodeCount:
        if residual[u * NodeCap + v] > 0 and parent[v] < 0:
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == sink: break
    if parent[sink] < 0: break
    var amount = demand - flow
    var vertex = sink
    while vertex != source:
      let u = parent[vertex]
      amount = min(amount, residual[u * NodeCap + vertex])
      vertex = u
    vertex = sink
    while vertex != source:
      let u = parent[vertex]
      residual[u * NodeCap + vertex] -= amount
      residual[vertex * NodeCap + u] += amount
      vertex = u
    flow += amount
  if flow == demand: 1 else: 0
