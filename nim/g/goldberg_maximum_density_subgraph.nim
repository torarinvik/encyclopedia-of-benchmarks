# Clean-room Goldberg exact maximum-density profile.
const MaxN = 8
const MaxM = 28
const MaxNetwork = 10

proc goldberg_maximum_density_subgraph*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "goldberg_maximum_density_subgraph".} =
  if input.isNil or length < csize_t(2) or length > csize_t(59): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 2 or n64 > MaxN.int64 or m64 < 0 or m64 > MaxM.int64 or int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[MaxN * MaxN, bool]
  var degree: array[MaxN, int64]
  var edgeU, edgeV: array[MaxM, int]
  for edge in 0 ..< m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u * MaxN + v]: return -1
    adjacent[u * MaxN + v] = true
    adjacent[v * MaxN + u] = true
    edgeU[edge] = u
    edgeV[edge] = v
    inc degree[u]
    inc degree[v]
  if m == 0: return 1

  var low = 0'i64
  var high = m64
  var denominator = 1'i64
  var best: array[MaxN, bool]
  while (high - low) * n64 * (n64 - 1) >= denominator:
    let low2 = 2 * low
    let high2 = 2 * high
    let midpoint = low + high
    let nextDenominator = 2 * denominator
    let source = n
    let sink = n + 1
    let networkSize = n + 2
    var residual: array[MaxNetwork * MaxNetwork, int64]
    for v in 0 ..< n:
      let sourceCapacity = m64 * nextDenominator
      residual[source * MaxNetwork + v] = sourceCapacity
      residual[v * MaxNetwork + sink] = sourceCapacity + 2 * midpoint - nextDenominator * degree[v]
    for edge in 0 ..< m:
      let u = edgeU[edge]
      let v = edgeV[edge]
      residual[u * MaxNetwork + v] += nextDenominator
      residual[v * MaxNetwork + u] += nextDenominator
    while true:
      var parent: array[MaxNetwork, int]
      for v in 0 ..< networkSize: parent[v] = -1
      var queue: array[MaxNetwork, int]
      var head = 0
      var tail = 0
      parent[source] = source
      queue[tail] = source
      inc tail
      while head < tail and parent[sink] == -1:
        let here = queue[head]
        inc head
        for there in 0 ..< networkSize:
          if parent[there] == -1 and residual[here * MaxNetwork + there] > 0:
            parent[there] = here
            queue[tail] = there
            inc tail
            if there == sink: break
      if parent[sink] == -1: break
      var amount = 1'i64 shl 60
      var vertex = sink
      while vertex != source:
        let previous = parent[vertex]
        amount = min(amount, residual[previous * MaxNetwork + vertex])
        vertex = previous
      vertex = sink
      while vertex != source:
        let previous = parent[vertex]
        residual[previous * MaxNetwork + vertex] -= amount
        residual[vertex * MaxNetwork + previous] += amount
        vertex = previous
    var reachable: array[MaxNetwork, bool]
    var queue2: array[MaxNetwork, int]
    var head2 = 0
    var tail2 = 0
    reachable[source] = true
    queue2[tail2] = source
    inc tail2
    while head2 < tail2:
      let here = queue2[head2]
      inc head2
      for there in 0 ..< networkSize:
        if not reachable[there] and residual[here * MaxNetwork + there] > 0:
          reachable[there] = true
          queue2[tail2] = there
          inc tail2
    var selected: array[MaxN, bool]
    var any = false
    for v in 0 ..< n:
      selected[v] = reachable[v]
      any = any or selected[v]
    if any:
      for v in 0 ..< n: best[v] = selected[v]
      low = midpoint
      high = high2
    else:
      low = low2
      high = midpoint
    denominator = nextDenominator
  var vertexCount = 0'i64
  var edgeCount = 0'i64
  for v in 0 ..< n:
    if best[v]: inc vertexCount
  if vertexCount == 0: return 1
  for edge in 0 ..< m:
    if best[edgeU[edge]] and best[edgeV[edge]]: inc edgeCount
  var a = edgeCount
  var b = vertexCount
  while b != 0:
    let r = a mod b
    a = b
    b = r
  (edgeCount div a) * (n64 + 1) + vertexCount div a
