## Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile.
const N = 12
const M = 24
const MaxInput = 2 + 2 * M

proc treeEdge(u, v: int, parent: array[N, int]): bool =
  parent[u] == v or parent[v] == u

proc criticalEdge(u, v: int, parent: array[N, int],
                  critical: array[N, bool]): bool =
  if parent[u] == v: return critical[u]
  if parent[v] == u: return critical[v]
  false

proc parentsBfs(n: int, adjacent: array[N, array[N, bool]],
                parent: var array[N, int], seen: var array[N, bool]) =
  var frontier: array[N, int]
  var following: array[N, int]
  var candidate: array[N, int]
  for root in 0..<n:
    if seen[root]: continue
    var count = 1
    frontier[0] = root
    parent[root] = root
    seen[root] = true
    while count != 0:
      var has: array[N, bool]
      for i in 0..<count:
        let vertex = frontier[i]
        for other in 0..<n:
          if adjacent[vertex][other] and not seen[other]:
            if not has[other] or vertex < candidate[other]:
              candidate[other] = vertex
            has[other] = true
      var nextCount = 0
      for other in 0..<n:
        if has[other]:
          parent[other] = candidate[other]
          seen[other] = true
          following[nextCount] = other
          inc nextCount
      for i in 0..<nextCount: frontier[i] = following[i]
      count = nextCount

proc assignPreorder(n: int, parent: array[N, int],
                    pn: var array[N, int], order: var array[N, int],
                    size: var array[N, int]) =
  var stack: array[N, int]
  var global = 0
  for root in 0..<n:
    if parent[root] != root: continue
    var top = 0
    var count = 0
    let begin = global
    stack[top] = root
    inc top
    while top != 0:
      dec top
      let vertex = stack[top]
      pn[vertex] = count
      inc count
      order[global] = vertex
      inc global
      for child in countdown(n - 1, 0):
        if child != vertex and parent[child] == vertex:
          stack[top] = child
          inc top
    var i = global
    while i > begin:
      dec i
      let vertex = order[i]
      if parent[vertex] != vertex: size[parent[vertex]] += size[vertex]

proc gbbs_biconnectivity*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_biconnectivity".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > N or m64 < 0 or m64 > M or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var adjacent: array[N, array[N, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
  if output.isNil or capacity < csize_t(m): return -2
  var parent: array[N, int]
  var pn, order: array[N, int]
  var size: array[N, int]
  var seen, critical: array[N, bool]
  for v in 0..<n:
    parent[v] = v
    size[v] = 1
  parentsBfs(n, adjacent, parent, seen)
  assignPreorder(n, parent, pn, order, size)
  var low = pn
  var high: array[N, int]
  for v in 0..<n: high[v] = pn[v] + size[v] - 1
  for edge in 0..<m:
    let u = int(input[2 + 2 * edge])
    let v = int(input[3 + 2 * edge])
    if not treeEdge(u, v, parent):
      if pn[u] < low[v]: low[v] = pn[u]
      elif pn[u] > high[v]: high[v] = pn[u]
      if pn[v] < low[u]: low[u] = pn[v]
      elif pn[v] > high[u]: high[u] = pn[v]
  for i in countdown(n - 1, 0):
    let vertex = order[i]
    if parent[vertex] != vertex:
      let p = parent[vertex]
      low[p] = min(low[p], low[vertex])
      high[p] = max(high[p], high[vertex])
  for v in 0..<n:
    let p = parent[v]
    if v != p and low[v] >= pn[p] and high[v] < pn[p] + size[p]:
      critical[v] = true
  var component: array[N, int]
  var queue: array[N, int]
  for v in 0..<n: component[v] = N
  for root in 0..<n:
    if component[root] != N: continue
    var head = 0
    var tail = 0
    component[root] = root
    queue[tail] = root
    inc tail
    while head < tail:
      let vertex = queue[head]
      inc head
      for other in 0..<n:
        if adjacent[vertex][other] and not criticalEdge(vertex, other, parent, critical) and
            component[other] == N:
          component[other] = root
          queue[tail] = other
          inc tail
  var raw: array[M, int]
  for edge in 0..<m:
    let u = int(input[2 + 2 * edge])
    let v = int(input[3 + 2 * edge])
    if parent[u] == v and critical[u]: raw[edge] = component[u]
    elif parent[v] == u and critical[v]: raw[edge] = component[v]
    else: raw[edge] = component[u]
  for edge in 0..<m:
    var label = m
    for other in 0..<m:
      if raw[other] == raw[edge]: label = min(label, other)
    output[edge] = uint8(label)
  return int64(m)
