const
  MaxVertices = 8
  MaxEdges = 24
  MaxInputValues = 4 + 3 * MaxEdges + 1
  FlowInfinity = 2401'i64

proc pushForward(vertex, sink: int, amount: int64, n: int,
    residual: var array[MaxVertices, array[MaxVertices, int64]],
    active: var array[MaxVertices, array[MaxVertices, bool]],
    incoming, outgoing: var array[MaxVertices, int64]): int64 =
  if vertex == sink: return amount
  var remaining = amount
  for next in 0 ..< n:
    if remaining == 0 or not active[vertex][next] or residual[vertex][next] == 0: continue
    let limit = min(remaining, residual[vertex][next])
    let pushed = pushForward(next, sink, limit, n, residual, active, incoming, outgoing)
    if pushed == 0: continue
    residual[vertex][next] -= pushed
    residual[next][vertex] += pushed
    outgoing[vertex] -= pushed
    incoming[next] -= pushed
    remaining -= pushed
    if residual[vertex][next] == 0: active[vertex][next] = false
  amount - remaining

proc pushBackward(vertex, source: int, amount: int64, n: int,
    residual: var array[MaxVertices, array[MaxVertices, int64]],
    active: var array[MaxVertices, array[MaxVertices, bool]],
    incoming, outgoing: var array[MaxVertices, int64]): int64 =
  if vertex == source: return amount
  var remaining = amount
  for previous in 0 ..< n:
    if remaining == 0 or not active[previous][vertex] or residual[previous][vertex] == 0: continue
    let limit = min(remaining, residual[previous][vertex])
    let pushed = pushBackward(previous, source, limit, n, residual, active, incoming, outgoing)
    if pushed == 0: continue
    residual[previous][vertex] -= pushed
    residual[vertex][previous] += pushed
    incoming[vertex] -= pushed
    outgoing[previous] -= pushed
    remaining -= pushed
    if residual[previous][vertex] == 0: active[previous][vertex] = false
  amount - remaining

proc removeVertex(vertex, n: int,
    residual: array[MaxVertices, array[MaxVertices, int64]],
    active: var array[MaxVertices, array[MaxVertices, bool]],
    incoming, outgoing: var array[MaxVertices, int64],
    alive: var array[MaxVertices, bool]) =
  for other in 0 ..< n:
    if active[other][vertex]:
      let capacity = residual[other][vertex]
      outgoing[other] -= capacity
      incoming[vertex] -= capacity
      active[other][vertex] = false
    if active[vertex][other]:
      let capacity = residual[vertex][other]
      outgoing[vertex] -= capacity
      incoming[other] -= capacity
      active[vertex][other] = false
  alive[vertex] = false

proc mpm_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mpm_maxflow".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let edgeCountValue = input[1]
  let sourceValue = input[2]
  let sinkValue = input[3]
  if nValue < 2 or nValue > int64(MaxVertices) or edgeCountValue < 0 or
      edgeCountValue > int64(MaxEdges) or sourceValue < 1 or sourceValue > nValue or
      sinkValue < 1 or sinkValue > nValue or sourceValue == sinkValue: return -1
  let n = int(nValue)
  let edgeCount = int(edgeCountValue)
  let source = int(sourceValue - 1)
  let sink = int(sinkValue - 1)
  if length != csize_t(4 + 3 * edgeCount): return -1

  var residual: array[MaxVertices, array[MaxVertices, int64]]
  for edge in 0 ..< edgeCount:
    let fromValue = input[4 + 3 * edge]
    let toValue = input[5 + 3 * edge]
    let capacity = input[6 + 3 * edge]
    if fromValue < 1 or fromValue > nValue or toValue < 1 or toValue > nValue or
        fromValue == toValue or capacity < 0 or capacity > 100: return -1
    residual[int(fromValue - 1)][int(toValue - 1)] += capacity

  var totalFlow = 0'i64
  while true:
    var level: array[MaxVertices, int]
    for vertex in 0 ..< n: level[vertex] = -1
    var queue: array[MaxVertices, int]
    var head = 0
    var tail = 0
    level[source] = 0
    queue[tail] = source
    inc tail
    while head < tail:
      let vertex = queue[head]
      inc head
      for next in 0 ..< n:
        if residual[vertex][next] > 0 and level[next] < 0:
          level[next] = level[vertex] + 1
          queue[tail] = next
          inc tail
    if level[sink] < 0: break

    var incoming, outgoing: array[MaxVertices, int64]
    var active: array[MaxVertices, array[MaxVertices, bool]]
    var alive: array[MaxVertices, bool]
    for vertex in 0 ..< n: alive[vertex] = level[vertex] >= 0 and level[vertex] <= level[sink]
    for from in 0 ..< n:
      for to in 0 ..< n:
        if level[from] >= 0 and level[from] < level[sink] and
            level[to] == level[from] + 1 and residual[from][to] > 0:
          active[from][to] = true
          outgoing[from] += residual[from][to]
          incoming[to] += residual[from][to]
    incoming[source] = FlowInfinity
    outgoing[sink] = FlowInfinity

    while true:
      var reference = -1
      var leastPotential = FlowInfinity + 1
      for vertex in 0 ..< n:
        if not alive[vertex]: continue
        let potential = min(incoming[vertex], outgoing[vertex])
        if potential < leastPotential:
          leastPotential = potential
          reference = vertex
      if reference < 0: break
      if leastPotential > 0:
        totalFlow += leastPotential
        discard pushBackward(reference, source, leastPotential, n,
          residual, active, incoming, outgoing)
        discard pushForward(reference, sink, leastPotential, n,
          residual, active, incoming, outgoing)
      removeVertex(reference, n, residual, active, incoming, outgoing, alive)
  totalFlow
