const
  MaxN = 16
  MaxQ = 32
  MaxE = 15
  MaxNodes = 75
  MaxInput = 143
  WeightLimit = 1000'i64
  EdgeBase = 0
  EdgeCompress = 1
  RakeZero = 2
  RakeMerge = 3
  RakeBranch = 4

type
  Cluster = object
    kind, a, b, c, parent, end0, end1, pivot, edge: int
    length, far0, far1, diameter, best1, best2: int64

proc farAt(nodes: array[MaxNodes, Cluster], id, vertex: int): int64 =
  if nodes[id].end0 == vertex: nodes[id].far0 else: nodes[id].far1

proc recalc(nodes: var array[MaxNodes, Cluster], id: int,
            weights: array[MaxE, int64]) =
  let x = nodes[id]
  case x.kind
  of EdgeBase:
    let w = weights[x.edge]
    nodes[id].length = w; nodes[id].far0 = w; nodes[id].far1 = w; nodes[id].diameter = w
  of RakeZero:
    nodes[id].best1 = 0; nodes[id].best2 = 0; nodes[id].diameter = 0
  of RakeMerge:
    let l = nodes[x.a]; let r = nodes[x.b]
    var first = 0'i64; var second = 0'i64
    for arm in [l.best1, l.best2, r.best1, r.best2]:
      if arm >= first: second = first; first = arm
      elif arm > second: second = arm
    nodes[id].best1 = first; nodes[id].best2 = second
    nodes[id].diameter = max(l.diameter, max(r.diameter, l.best1 + r.best1))
  of RakeBranch:
    let e = nodes[x.a]; let local = nodes[x.b]
    let center = farAt(nodes, x.a, x.end0)
    let pivotFar = farAt(nodes, x.a, x.pivot)
    nodes[id].best1 = max(center, e.length + local.best1)
    nodes[id].best2 = 0
    nodes[id].diameter = max(e.diameter, max(local.diameter, pivotFar + local.best1))
  else:
    let a = nodes[x.a]; let b = nodes[x.b]; let local = nodes[x.c]
    let ay = farAt(nodes, x.a, x.end0); let ap = farAt(nodes, x.a, x.pivot)
    let bp = farAt(nodes, x.b, x.pivot); let bz = farAt(nodes, x.b, x.end1)
    nodes[id].length = a.length + b.length
    nodes[id].far0 = max(ay, a.length + max(bp, local.best1))
    nodes[id].far1 = max(bz, b.length + max(ap, local.best1))
    nodes[id].diameter = max(a.diameter, max(b.diameter, max(local.diameter,
      max(ap + bp, max(ap + local.best1, bp + local.best1)))))

proc append(nodes: var array[MaxNodes, Cluster], count: var int, kind: int,
            weights: array[MaxE, int64], a, b, c, end0, end1, pivot, edge: int): int =
  if count >= MaxNodes: return -1
  result = count; inc count
  nodes[result] = Cluster(kind: kind, a: a, b: b, c: c, parent: -1,
                          end0: end0, end1: end1, pivot: pivot, edge: edge)
  for child in [a, b, c]:
    if child >= 0: nodes[child].parent = result
  recalc(nodes, result, weights)

proc makeRake(nodes: var array[MaxNodes, Cluster], count: var int,
              weights: array[MaxE, int64], base: int,
              branches: array[MaxN, int], branchCount: int): int =
  var level, next: array[MaxN + 1, int]
  var len = 1; level[0] = base
  for i in 0 ..< branchCount: level[len] = branches[i]; inc len
  while len > 1:
    var nextLen = 0; var i = 0
    while i < len:
      if i + 1 == len: next[nextLen] = level[i]; inc nextLen
      else:
        let merged = append(nodes, count, RakeMerge, weights, level[i], level[i+1], -1, -1, -1, -1, -1)
        if merged < 0: return -1
        next[nextLen] = merged; inc nextLen
      i += 2
    for j in 0 ..< nextLen: level[j] = next[j]
    len = nextLen
  level[0]

proc neighborCount(adj: array[MaxN, array[MaxN, bool]], active: array[MaxN, bool],
                   n, vertex: int, output: var array[2, int]): int =
  for other in 0 ..< n:
    if active[other] and adj[vertex][other]:
      if result < 2: output[result] = other
      inc result

proc findRoot(parent: var array[MaxN, int], vertex: int): int =
  result = vertex
  while parent[result] != result:
    parent[result] = parent[parent[result]]
    result = parent[result]

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc dynamic_top_tree_component_diameter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_top_tree_component_diameter".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nv = input[0]; let qv = input[1]
  if nv < 1 or nv > MaxN or qv < 0 or qv > MaxQ: return -1
  let n = int(nv); let q = int(qv); let edgeEnd = 2 + 3 * (n - 1)
  if int(length) != edgeEnd + 3 * q: return -1
  var edgeU, edgeV: array[MaxE, int]
  var dsu: array[MaxN, int]
  var weights: array[MaxE, int64]
  for v in 0 ..< n: dsu[v] = v
  for e in 0 ..< n - 1:
    let off = 2 + 3 * e
    let uv = input[off]; let vv = input[off+1]; let w = input[off+2]
    if uv < 0 or uv >= nv or vv < 0 or vv >= nv or uv == vv or w < 0 or w > WeightLimit: return -1
    let u = int(uv); let v = int(vv)
    let ru = findRoot(dsu, u); let rv = findRoot(dsu, v)
    if ru == rv: return -1
    dsu[ru] = rv; edgeU[e] = u; edgeV[e] = v; weights[e] = w
  let treeRoot = findRoot(dsu, 0)
  for v in 1 ..< n:
    if findRoot(dsu, v) != treeRoot: return -1

  var opCode: array[MaxQ, int]
  var opEdge: array[MaxQ, int]
  var opValue: array[MaxQ, int64]
  var queryCount = 0
  for t in 0 ..< q:
    let off = edgeEnd + 3*t
    let opcode = input[off]; let edge = input[off+1]; let value = input[off+2]
    if opcode == 0:
      if edge < 0 or edge >= n-1 or value < 0 or value > WeightLimit: return -1
    elif opcode == 1:
      if edge != 0 or value != 0: return -1
      inc queryCount
    else: return -1
    opCode[t] = int(opcode); opEdge[t] = int(edge); opValue[t] = value
  let outputBytes = 8 * queryCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2

  var nodes: array[MaxNodes, Cluster]
  var nodeCount = 0
  var baseRake: array[MaxN, int]
  var baseEdge: array[MaxE, int]
  var adj: array[MaxN, array[MaxN, bool]]
  var active: array[MaxN, bool]
  var edgeCluster: array[MaxN, array[MaxN, int]]
  var branches: array[MaxN, array[MaxN, int]]
  var branchCount: array[MaxN, int]
  for u in 0 ..< MaxN:
    for v in 0 ..< MaxN: edgeCluster[u][v] = -1
  for v in 0 ..< n:
    active[v] = true
    baseRake[v] = append(nodes, nodeCount, RakeZero, weights, -1, -1, -1, -1, -1, -1, -1)
    if baseRake[v] < 0: return -1
  for e in 0 ..< n-1:
    let u = edgeU[e]; let v = edgeV[e]
    let cluster = append(nodes, nodeCount, EdgeBase, weights, -1, -1, -1, u, v, -1, e)
    if cluster < 0: return -1
    baseEdge[e] = cluster; adj[u][v] = true; adj[v][u] = true
    edgeCluster[u][v] = cluster; edgeCluster[v][u] = cluster

  var activeCount = n
  while activeCount > 1:
    if activeCount == 2:
      var pair: array[2, int]; var found = 0
      for v in 0 ..< n:
        if active[v]: pair[found] = v; inc found
      let x = pair[0]; let y = pair[1]
      let local = makeRake(nodes, nodeCount, weights, baseRake[x], branches[x], branchCount[x])
      if local < 0: return -1
      let branch = append(nodes, nodeCount, RakeBranch, weights, edgeCluster[x][y], local, -1, y, -1, x, -1)
      if branch < 0 or branchCount[y] >= MaxN: return -1
      branches[y][branchCount[y]] = branch; inc branchCount[y]
      adj[x][y] = false; adj[y][x] = false; edgeCluster[x][y] = -1; edgeCluster[y][x] = -1
      active[x] = false; dec activeCount
      break
    var leaves, leafNeighbor: array[MaxN, int]
    var leafCount = 0
    for v in 0 ..< n:
      if active[v]:
        var adjacent: array[2, int]
        if neighborCount(adj, active, n, v, adjacent) == 1:
          leaves[leafCount] = v; leafNeighbor[leafCount] = adjacent[0]; inc leafCount
    for i in 0 ..< leafCount:
      let x = leaves[i]; let y = leafNeighbor[i]
      let local = makeRake(nodes, nodeCount, weights, baseRake[x], branches[x], branchCount[x])
      if local < 0: return -1
      let branch = append(nodes, nodeCount, RakeBranch, weights, edgeCluster[x][y], local, -1, y, -1, x, -1)
      if branch < 0 or branchCount[y] >= MaxN: return -1
      branches[y][branchCount[y]] = branch; inc branchCount[y]
    for i in 0 ..< leafCount:
      let x = leaves[i]; let y = leafNeighbor[i]
      adj[x][y] = false; adj[y][x] = false; edgeCluster[x][y] = -1; edgeCluster[y][x] = -1
      active[x] = false; dec activeCount
    if activeCount <= 1: break
    var chosen: array[MaxN, bool]
    var compressVertices: array[MaxN, int]
    var compressCount = 0
    for x in 0 ..< n:
      if active[x]:
        var adjacent: array[2, int]
        if neighborCount(adj, active, n, x, adjacent) != 2: continue
        if not chosen[adjacent[0]] and not chosen[adjacent[1]]:
          chosen[x] = true; compressVertices[compressCount] = x; inc compressCount
    var px, py, pz: array[MaxN, int]
    var pc: array[MaxN, int]
    for i in 0 ..< compressCount:
      let x = compressVertices[i]
      var adjacent: array[2, int]
      discard neighborCount(adj, active, n, x, adjacent)
      let y = adjacent[0]; let z = adjacent[1]
      let local = makeRake(nodes, nodeCount, weights, baseRake[x], branches[x], branchCount[x])
      if local < 0: return -1
      let cluster = append(nodes, nodeCount, EdgeCompress, weights, edgeCluster[y][x], edgeCluster[x][z], local, y, z, x, -1)
      if cluster < 0: return -1
      px[i] = x; py[i] = y; pz[i] = z; pc[i] = cluster
    for i in 0 ..< compressCount:
      let x = px[i]; let y = py[i]; let z = pz[i]
      adj[y][x] = false; adj[x][y] = false; adj[x][z] = false; adj[z][x] = false
      edgeCluster[y][x] = -1; edgeCluster[x][y] = -1; edgeCluster[x][z] = -1; edgeCluster[z][x] = -1
      active[x] = false; dec activeCount
    for i in 0 ..< compressCount:
      let y = py[i]; let z = pz[i]
      adj[y][z] = true; adj[z][y] = true; edgeCluster[y][z] = pc[i]; edgeCluster[z][y] = pc[i]

  var rootVertex = 0
  while not active[rootVertex]: inc rootVertex
  let root = makeRake(nodes, nodeCount, weights, baseRake[rootVertex], branches[rootVertex], branchCount[rootVertex])
  if root < 0: return -1
  var staged: array[MaxQ, int64]
  var stagedCount = 0
  for t in 0 ..< q:
    if opCode[t] == 0:
      let edge = opEdge[t]
      weights[edge] = opValue[t]
      var node = baseEdge[edge]
      recalc(nodes, node, weights)
      var ancestor = nodes[node].parent
      while ancestor >= 0:
        node = ancestor; recalc(nodes, node, weights); ancestor = nodes[node].parent
    else:
      staged[stagedCount] = nodes[root].diameter; inc stagedCount
  for i in 0 ..< stagedCount: storeLe(output, 8*i, staged[i])
  int64(outputBytes)
