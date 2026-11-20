const
  MaxN = 6
  MaxM = 8
  MaxInputLength = 37
  NodeCap = 8

proc feasible(input: ptr UncheckedArray[int64], n, m, source, sink: int,
              flowCap: int64): bool =
  var residual: array[NodeCap * NodeCap, int64]
  var balance: array[MaxN, int64]
  for index in 0 ..< m:
    let offset = 4 + 4 * index
    let u = int(input[offset])
    let v = int(input[offset + 1])
    let lower = input[offset + 2]
    let upper = input[offset + 3]
    residual[u * NodeCap + v] += upper - lower
    balance[u] -= lower
    balance[v] += lower
  residual[sink * NodeCap + source] += flowCap

  let superSource = n
  let superSink = n + 1
  let nodeCount = n + 2
  var demand = 0'i64
  for vertex in 0 ..< n:
    if balance[vertex] > 0:
      residual[superSource * NodeCap + vertex] += balance[vertex]
      demand += balance[vertex]
    elif balance[vertex] < 0:
      residual[vertex * NodeCap + superSink] -= balance[vertex]

  var flow = 0'i64
  while flow < demand:
    var parent: array[NodeCap, int]
    for vertex in 0 ..< nodeCount: parent[vertex] = -1
    var queue: array[NodeCap, int]
    var head = 0
    var tail = 0
    parent[superSource] = superSource
    queue[tail] = superSource
    inc tail
    while head < tail and parent[superSink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< nodeCount:
        if residual[u * NodeCap + v] > 0 and parent[v] < 0:
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == superSink: break
    if parent[superSink] < 0: break
    var amount = demand - flow
    var vertex = superSink
    while vertex != superSource:
      let u = parent[vertex]
      amount = min(amount, residual[u * NodeCap + vertex])
      vertex = u
    vertex = superSink
    while vertex != superSource:
      let u = parent[vertex]
      residual[u * NodeCap + vertex] -= amount
      residual[vertex * NodeCap + u] += amount
      vertex = u
    flow += amount
  flow == demand

proc minimum_bounded_s_t_flow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_bounded_s_t_flow".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nArg = input[0]
  let mArg = input[1]
  let sourceArg = input[2]
  let sinkArg = input[3]
  if nArg < 2 or nArg > MaxN or mArg < 0 or mArg > MaxM: return -1
  if sourceArg < 0 or sourceArg >= nArg or sinkArg < 0 or sinkArg >= nArg or
      sourceArg == sinkArg: return -1
  let n = int(nArg)
  let m = int(mArg)
  let source = int(sourceArg)
  let sink = int(sinkArg)
  if length != csize_t(4 + 4 * m): return -1

  var upperBound = 0'i64
  for index in 0 ..< m:
    let offset = 4 + 4 * index
    let uArg = input[offset]
    let vArg = input[offset + 1]
    let lower = input[offset + 2]
    let upper = input[offset + 3]
    if uArg < 0 or uArg >= nArg or vArg < 0 or vArg >= nArg or lower < 0 or
        upper < lower or upper > 2: return -1
    if int(uArg) == source and int(vArg) != source: upperBound += upper

  var low = 0'i64
  var high = upperBound + 1
  while low < high:
    let middle = low + (high - low) div 2
    if feasible(input, n, m, source, sink, middle): high = middle
    else: low = middle + 1
  if low > upperBound: -2 else: low
