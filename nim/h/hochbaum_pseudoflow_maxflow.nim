const
  PF_N = 8
  PF_K = 6
  PF_M = 24
  PF_ITERATIONS = 512

proc pfBuildState(k: int, rootEdge: array[PF_K, int], treeEdges: array[PF_N, int], treeCount: int,
                  edgeU, edgeV: array[PF_M, int], parent: var array[PF_N + 1, int],
                  parentEdge: var array[PF_N + 1, int], branchRoot: var array[PF_K, int]): bool =
  let root = k
  var adjacency: array[(PF_N + 1) * (PF_N + 1), int]
  for i in 0 ..< adjacency.len: adjacency[i] = -2
  for v in 0 ..< k:
    if rootEdge[v] != 0:
      adjacency[root * 9 + v] = -1
      adjacency[v * 9 + root] = -1
  for i in 0 ..< treeCount:
    let e = treeEdges[i]
    let u = edgeU[e]
    let v = edgeV[e]
    adjacency[u * 9 + v] = e
    adjacency[v * 9 + u] = e
  for i in 0 ..< PF_N + 1:
    parent[i] = -2
    parentEdge[i] = -2
  for i in 0 ..< k: branchRoot[i] = -1
  var queue: array[PF_N + 1, int]
  var head = 0
  var tail = 1
  parent[root] = -1
  queue[0] = root
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 .. k:
      if adjacency[u * 9 + v] != -2 and parent[v] == -2:
        parent[v] = u
        parentEdge[v] = adjacency[u * 9 + v]
        branchRoot[v] = if u == root: v else: branchRoot[u]
        queue[tail] = v
        inc tail
  tail == k + 1

proc pfBalance(k, edgeCount: int, weight: array[PF_K, int64], edgeU, edgeV: array[PF_M, int],
               flow: array[PF_M, int64], balance: var array[PF_K, int64]) =
  for v in 0 ..< k: balance[v] = weight[v]
  for e in 0 ..< edgeCount:
    balance[edgeU[e]] -= flow[e]
    balance[edgeV[e]] += flow[e]

proc pfInTree(treeEdges: array[PF_N, int], treeCount, edge: int): bool =
  for i in 0 ..< treeCount:
    if treeEdges[i] == edge: return true
  false

proc pfRemoveTreeEdge(treeEdges: var array[PF_N, int], treeCount: var int, edge: int): bool =
  for i in 0 ..< treeCount:
    if treeEdges[i] == edge:
      for j in i ..< treeCount - 1: treeEdges[j] = treeEdges[j + 1]
      dec treeCount
      return true
  false

proc hochbaum_pseudoflow_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hochbaum_pseudoflow_maxflow".} =
  if input.isNil or length < 4 or length > 77: return -1
  let nv = input[0]
  let mv = input[1]
  let sr = input[2]
  let tr = input[3]
  if nv < 2 or nv > 8 or mv < 0 or mv > 24 or sr < 1 or sr > nv or tr < 1 or tr > nv or sr == tr: return -1
  let n = int(nv)
  let m = int(mv)
  let source = int(sr - 1)
  let sink = int(tr - 1)
  if length != csize_t(4 + 3 * m): return -1
  var local: array[PF_N, int]
  for v in 0 ..< n: local[v] = -1
  var k = 0
  for v in 0 ..< n:
    if v != source and v != sink:
      local[v] = k
      inc k
  var sourceCap, sinkCap: array[PF_K, int64]
  var directCap: int64 = 0
  var edgeU, edgeV: array[PF_M, int]
  var capacity, flow: array[PF_M, int64]
  var edgeCount = 0
  for i in 0 ..< m:
    let ur = input[4 + 3 * i]
    let vr = input[5 + 3 * i]
    let cap = input[6 + 3 * i]
    if ur < 1 or ur > nv or vr < 1 or vr > nv or ur == vr or cap < 0 or cap > 100: return -1
    let u = int(ur - 1)
    let v = int(vr - 1)
    if u == source:
      if v == sink: directCap += cap
      else: sourceCap[local[v]] += cap
    elif v == sink: sinkCap[local[u]] += cap
    elif v == source or u == sink: return -1
    else:
      edgeU[edgeCount] = local[u]
      edgeV[edgeCount] = local[v]
      capacity[edgeCount] = cap
      inc edgeCount
  var weight, balance: array[PF_K, int64]
  var label, ticket: array[PF_K, int64]
  var nextTicket: int64 = 0
  var rootEdge: array[PF_K, int]
  var treeEdges: array[PF_N, int]
  var treeCount = 0
  for v in 0 ..< k:
    weight[v] = sourceCap[v] - sinkCap[v]
    rootEdge[v] = 1
    label[v] = 1
    ticket[v] = nextTicket
    inc nextTicket
  var parent: array[PF_N + 1, int]
  var parentEdge: array[PF_N + 1, int]
  var branchRoot: array[PF_K, int]

  for iteration in 0 ..< PF_ITERATIONS:
    pfBalance(k, edgeCount, weight, edgeU, edgeV, flow, balance)
    if not pfBuildState(k, rootEdge, treeEdges, treeCount, edgeU, edgeV, parent, parentEdge, branchRoot): return -1
    var active, strong: array[PF_K, int]
    let oldLabel = label
    for r in 0 ..< k:
      if rootEdge[r] != 0 and balance[r] > 0: active[r] = 1
    for v in 0 ..< k: strong[v] = if balance[branchRoot[v]] > 0: 1 else: 0
    var crossing = false
    for e in 0 ..< edgeCount:
      let u = edgeU[e]
      let v = edgeV[e]
      if strong[u] != 0 and strong[v] == 0 and capacity[e] - flow[e] > 0: crossing = true
      if strong[v] != 0 and strong[u] == 0 and flow[e] > 0: crossing = true
    if not crossing:
      var cut = directCap
      for v in 0 ..< k:
        if strong[v] != 0: cut += sinkCap[v]
        else: cut += sourceCap[v]
      for e in 0 ..< edgeCount:
        if strong[edgeU[e]] != 0 and strong[edgeV[e]] == 0: cut += capacity[e]
      return if cut >= 0 and cut <= 2400: cut else: -1
    var strongRoot = -1
    for r in 0 ..< k:
      if active[r] != 0 and (strongRoot < 0 or label[r] > label[strongRoot] or (label[r] == label[strongRoot] and ticket[r] < ticket[strongRoot])):
        strongRoot = r
    if strongRoot < 0: return -1
    var low: int64 = 1000
    for v in 0 ..< k:
      if branchRoot[v] == strongRoot and label[v] < low: low = label[v]
    var tail = -1
    var headNode = -1
    var entering = -1
    for v in 0 ..< k:
      if entering < 0 and branchRoot[v] == strongRoot and label[v] == low:
        for e in 0 ..< edgeCount:
          if entering < 0 and not pfInTree(treeEdges, treeCount, e):
            let u = edgeU[e]
            let w = edgeV[e]
            if u == v and capacity[e] - flow[e] > 0 and branchRoot[w] != strongRoot and label[w] == low - 1:
              tail = v; headNode = w; entering = e
            elif w == v and flow[e] > 0 and branchRoot[u] != strongRoot and label[u] == low - 1:
              tail = v; headNode = u; entering = e
    if entering < 0:
      var relabel = -1
      for v in 0 ..< k:
        if relabel < 0 and branchRoot[v] == strongRoot and label[v] == low:
          var childrenOk = true
          for child in 0 ..< k:
            if parent[child] == v and label[child] < low + 1: childrenOk = false
          if childrenOk: relabel = v
      if relabel < 0: return -1
      inc label[relabel]
      if relabel == strongRoot: ticket[strongRoot] = nextTicket; inc nextTicket
      continue
    let targetRoot = branchRoot[headNode]
    let root = k
    var chain: array[PF_N + 1, int]
    var chainLen = 0
    var cursor = tail
    while cursor != root:
      chain[chainLen] = cursor
      inc chainLen
      cursor = parent[cursor]
    var stepFrom, stepTo, stepEdge: array[2 * PF_N + 2, int]
    var steps = 0
    for j in countdown(chainLen - 1, 0):
      let child = chain[j]
      if parent[child] != root:
        stepFrom[steps] = parent[child]
        stepTo[steps] = child
        stepEdge[steps] = parentEdge[child]
        inc steps
    stepFrom[steps] = tail; stepTo[steps] = headNode; stepEdge[steps] = entering; inc steps
    cursor = headNode
    while cursor != targetRoot:
      stepFrom[steps] = cursor
      stepTo[steps] = parent[cursor]
      stepEdge[steps] = parentEdge[cursor]
      inc steps
      cursor = parent[cursor]
    rootEdge[strongRoot] = 0
    treeEdges[treeCount] = entering
    inc treeCount
    for j in 0 ..< chainLen: label[chain[j]] = label[headNode] + 1
    var carry = balance[strongRoot]
    for j in 0 ..< steps:
      let e = stepEdge[j]
      let u = edgeU[e]
      let v = edgeV[e]
      let residual = if stepFrom[j] == u and stepTo[j] == v: capacity[e] - flow[e] else: flow[e]
      let pushed = if carry < residual: carry else: residual
      if stepFrom[j] == u and stepTo[j] == v: flow[e] += pushed
      else: flow[e] -= pushed
      if residual < carry:
        if not pfRemoveTreeEdge(treeEdges, treeCount, e): return -1
        rootEdge[stepFrom[j]] = 1
      carry = pushed
      if carry == 0: break
    pfBalance(k, edgeCount, weight, edgeU, edgeV, flow, balance)
    if not pfBuildState(k, rootEdge, treeEdges, treeCount, edgeU, edgeV, parent, parentEdge, branchRoot): return -1
    for r in 0 ..< k:
      if rootEdge[r] != 0 and balance[r] > 0 and (active[r] == 0 or label[r] != oldLabel[r]): ticket[r] = nextTicket; inc nextTicket
  -1
