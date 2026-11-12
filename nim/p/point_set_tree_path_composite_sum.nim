const
  MaxN = 16
  MaxQ = 32
  MaxE = 15
  MaxNodes = 75
  MaxInput = 238
  Modulus = 998244353'i64
  VertexKind = 0
  EdgeKind = 1
  RakeKind = 2
  BranchKind = 3
  AttachKind = 4
  CompressKind = 5

type
  Affine = object
    mul, add: int64
  Cluster = object
    kind, a, b, parent, shared, boundary0, boundary1, boundaryCount, edgeId: int
    has0, has1: bool
    mask: uint16
    count: int32
    sum0, sum1: int64
    forward, reverse: Affine
  Context = object
    sum0, count0, sum1, count1: int64

proc norm(x: int64): int64 =
  result = x mod Modulus
  if result < 0: result += Modulus

proc identity(): Affine = Affine(mul: 1, add: 0)
proc compose(outer, inner: Affine): Affine =
  Affine(mul: outer.mul * inner.mul mod Modulus,
         add: (outer.mul * inner.add + outer.add) mod Modulus)
proc apply(map: Affine, sum, count: int64): int64 =
  (map.mul * sum + map.add * count) mod Modulus
proc boundaryIndex(node: Cluster, vertex: int): int =
  if node.boundary0 == vertex: return 0
  if node.boundaryCount == 2 and node.boundary1 == vertex: return 1
  -1
proc has(node: Cluster, vertex: int): bool =
  case boundaryIndex(node, vertex)
  of 0: node.has0
  of 1: node.has1
  else: false
proc sumAt(node: Cluster, vertex: int): int64 =
  if boundaryIndex(node, vertex) == 0: node.sum0 else: node.sum1
proc mapAt(node: Cluster, fromVertex, toVertex: int): Affine =
  if fromVertex == toVertex or node.boundaryCount != 2: return identity()
  if node.boundary0 == fromVertex and node.boundary1 == toVertex: node.forward else: node.reverse

proc recalc(nodes: var array[MaxNodes, Cluster], id: int,
            values: var array[MaxN, int64], edges: var array[MaxE, Affine]) =
  let x = nodes[id]
  if x.kind == VertexKind:
    nodes[id].count = 1
    nodes[id].mask = uint16(1 shl x.boundary0)
    nodes[id].sum0 = values[x.boundary0]
    nodes[id].has0 = true
    return
  if x.kind == EdgeKind:
    nodes[id].forward = edges[x.edgeId]
    nodes[id].reverse = edges[x.edgeId]
    return
  let a = nodes[x.a]
  let b = nodes[x.b]
  let overlap = has(a, x.shared) and has(b, x.shared)
  let removed = if overlap: 1 else: 0
  let duplicate = if overlap: values[x.shared] else: 0'i64
  nodes[id].count = a.count + b.count - int32(removed)
  nodes[id].mask = a.mask or b.mask
  let boundaries = [x.boundary0, x.boundary1]
  for index in 0 ..< x.boundaryCount:
    let boundary = boundaries[index]
    var total: int64
    if boundary == x.shared:
      total = norm(sumAt(a, x.shared) + sumAt(b, x.shared) - duplicate)
    elif boundaryIndex(a, boundary) >= 0:
      let sibling = norm(sumAt(b, x.shared) - duplicate)
      total = (sumAt(a, boundary) + apply(mapAt(a, boundary, x.shared), sibling,
               int64(b.count - int32(removed)))) mod Modulus
    else:
      let sibling = norm(sumAt(a, x.shared) - duplicate)
      total = (sumAt(b, boundary) + apply(mapAt(b, boundary, x.shared), sibling,
               int64(a.count - int32(removed)))) mod Modulus
    let boundaryHas = has(a, boundary) or has(b, boundary)
    if index == 0:
      nodes[id].sum0 = total
      nodes[id].has0 = boundaryHas
    else:
      nodes[id].sum1 = total
      nodes[id].has1 = boundaryHas
  if x.boundaryCount == 2:
    let u = x.boundary0
    let v = x.boundary1
    let aHasU = boundaryIndex(a, u) >= 0
    let aHasV = boundaryIndex(a, v) >= 0
    let bHasU = boundaryIndex(b, u) >= 0
    let bHasV = boundaryIndex(b, v) >= 0
    if aHasU and aHasV:
      nodes[id].forward = mapAt(a, u, v)
      nodes[id].reverse = mapAt(a, v, u)
    elif bHasU and bHasV:
      nodes[id].forward = mapAt(b, u, v)
      nodes[id].reverse = mapAt(b, v, u)
    else:
      nodes[id].forward = compose(mapAt(a, u, x.shared), mapAt(b, x.shared, v))
      nodes[id].reverse = compose(mapAt(b, v, x.shared), mapAt(a, x.shared, u))

proc append(nodes: var array[MaxNodes, Cluster], used: var int, kind, aId, bId, shared: int,
            values: var array[MaxN, int64], edges: var array[MaxE, Affine]): int =
  if used >= MaxNodes: return -1
  result = used
  inc used
  var node = Cluster(kind: kind, a: aId, b: bId, parent: -1, shared: shared,
                      edgeId: -1, forward: identity(), reverse: identity())
  if kind == VertexKind:
    node.boundary0 = shared
    node.boundaryCount = 1
  elif kind == EdgeKind:
    node.boundary0 = aId
    node.boundary1 = bId
    node.boundaryCount = 2
    node.edgeId = shared
  else:
    let a = nodes[aId]
    let b = nodes[bId]
    let aOther = if a.boundaryCount == 2 and a.boundary0 == shared: a.boundary1 else: a.boundary0
    let bOther = if b.boundaryCount == 2 and b.boundary0 == shared: b.boundary1 else: b.boundary0
    case kind
    of RakeKind:
      node.boundary0 = shared
      node.boundaryCount = 1
    of BranchKind:
      node.boundary0 = aOther
      node.boundaryCount = 1
    of AttachKind:
      node.boundary0 = a.boundary0
      node.boundary1 = a.boundary1
      node.boundaryCount = 2
    else:
      node.boundary0 = aOther
      node.boundary1 = bOther
      node.boundaryCount = 2
    nodes[aId].parent = result
    nodes[bId].parent = result
  nodes[result] = node
  recalc(nodes, result, values, edges)

proc makeRake(nodes: var array[MaxNodes, Cluster], used: var int, base: int,
              branches: var array[MaxN, int8], branchCount: int,
              values: var array[MaxN, int64], edges: var array[MaxE, Affine]): int =
  var level, next: array[MaxN + 1, int]
  var count = 1
  level[0] = base
  for i in 0 ..< branchCount:
    level[count] = int(branches[i])
    inc count
  while count > 1:
    var nextCount = 0
    var i = 0
    while i < count:
      if i + 1 == count:
        next[nextCount] = level[i]
        inc nextCount
      else:
        let shared = nodes[level[i]].boundary0
        let merged = append(nodes, used, RakeKind, level[i], level[i+1], shared, values, edges)
        if merged < 0: return -1
        next[nextCount] = merged
        inc nextCount
      i += 2
    for i in 0 ..< nextCount: level[i] = next[i]
    count = nextCount
  level[0]

proc neighborCount(adj: var array[MaxN, array[MaxN, bool]], active: var array[MaxN, bool],
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

proc contextAt(node: Cluster, context: Context, vertex: int): tuple[sum, count: int64] =
  let index = boundaryIndex(node, vertex)
  if index == 0: (context.sum0, context.count0)
  elif index == 1: (context.sum1, context.count1)
  else: (0'i64, 0'i64)

proc childContext(nodes: var array[MaxNodes, Cluster], parentId, childId: int,
                  context: Context, values: var array[MaxN, int64]): Context =
  let parent = nodes[parentId]
  let child = nodes[childId]
  let siblingId = if childId == parent.a: parent.b else: parent.a
  let sibling = nodes[siblingId]
  let shared = parent.shared
  let overlap = has(child, shared) and has(sibling, shared)
  let removed = if overlap: 1'i64 else: 0'i64
  var sumShared = norm(sumAt(sibling, shared) - (if overlap: values[shared] else: 0'i64))
  var countShared = int64(sibling.count) - removed
  let siblingBoundaries = [sibling.boundary0, sibling.boundary1]
  for i in 0 ..< sibling.boundaryCount:
    let boundary = siblingBoundaries[i]
    if boundaryIndex(parent, boundary) < 0: continue
    let outside = contextAt(parent, context, boundary)
    sumShared = (sumShared + apply(mapAt(sibling, shared, boundary), outside.sum, outside.count)) mod Modulus
    countShared += outside.count
  let childBoundaries = [child.boundary0, child.boundary1]
  for i in 0 ..< child.boundaryCount:
    let boundary = childBoundaries[i]
    var sum, count: int64
    if boundary == shared:
      sum = sumShared
      count = countShared
    else:
      sum = apply(mapAt(child, boundary, shared), sumShared, countShared)
      count = countShared
    if boundary != shared and boundaryIndex(parent, boundary) >= 0:
      let outside = contextAt(parent, context, boundary)
      sum = (sum + outside.sum) mod Modulus
      count += outside.count
    if i == 0:
      result.sum0 = sum
      result.count0 = count
    else:
      result.sum1 = sum
      result.count1 = count

proc query(nodes: var array[MaxNodes, Cluster], root: int, vertexLeaf: var array[MaxN, int],
           vertex: int, values: var array[MaxN, int64]): int64 =
  var path: array[MaxNodes, int]
  var len = 1
  path[0] = vertexLeaf[vertex]
  while path[len - 1] != root and len < MaxNodes:
    let parent = nodes[path[len - 1]].parent
    if parent < 0: return -1
    path[len] = parent
    inc len
  if path[len - 1] != root: return -1
  var context: Context
  for i in countdown(len - 1, 1):
    context = childContext(nodes, path[i], path[i - 1], context, values)
  (nodes[vertexLeaf[vertex]].sum0 + context.sum0) mod Modulus

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc point_set_tree_path_composite_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "point_set_tree_path_composite_sum".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nr = input[0]
  let qr = input[1]
  if nr < 1 or nr > MaxN or qr < 1 or qr > MaxQ: return -1
  let n = int(nr)
  let q = int(qr)
  var cursor = 2
  var values: array[MaxN, int64]
  for v in 0 ..< n:
    if cursor >= int(length): return -1
    values[v] = input[cursor]
    inc cursor
    if values[v] < 0 or values[v] >= Modulus: return -1
  var edgeU, edgeV: array[MaxE, int]
  var edges: array[MaxE, Affine]
  var dsu: array[MaxN, int]
  for v in 0 ..< n: dsu[v] = v
  for e in 0 ..< n - 1:
    if cursor + 4 > int(length): return -1
    let ur = input[cursor]
    let vr = input[cursor + 1]
    let mul = input[cursor + 2]
    let add = input[cursor + 3]
    cursor += 4
    if ur < 0 or ur >= nr or vr < 0 or vr >= nr or ur == vr or mul < 1 or mul >= Modulus or add < 0 or add >= Modulus: return -1
    let u = int(ur)
    let v = int(vr)
    let ru = findRoot(dsu, u)
    let rv = findRoot(dsu, v)
    if ru == rv: return -1
    dsu[ru] = rv
    edgeU[e] = u
    edgeV[e] = v
    edges[e] = Affine(mul: mul, add: add)
  let treeRoot = findRoot(dsu, 0)
  for v in 1 ..< n:
    if findRoot(dsu, v) != treeRoot: return -1
  var opCode: array[MaxQ, int]
  var opItem, opRoot: array[MaxQ, int]
  var opFirst, opSecond: array[MaxQ, int64]
  for i in 0 ..< q:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    if opcode == 0:
      if cursor + 3 > int(length): return -1
      let item = input[cursor]
      let value = input[cursor + 1]
      let root = input[cursor + 2]
      cursor += 3
      if item < 0 or item >= nr or value < 0 or value >= Modulus or root < 0 or root >= nr: return -1
      opCode[i] = 0
      opItem[i] = int(item)
      opFirst[i] = value
      opRoot[i] = int(root)
    elif opcode == 1:
      if cursor + 4 > int(length): return -1
      let item = input[cursor]
      let mul = input[cursor + 1]
      let add = input[cursor + 2]
      let root = input[cursor + 3]
      cursor += 4
      if item < 0 or item >= nr - 1 or mul < 1 or mul >= Modulus or add < 0 or add >= Modulus or root < 0 or root >= nr: return -1
      opCode[i] = 1
      opItem[i] = int(item)
      opFirst[i] = mul
      opSecond[i] = add
      opRoot[i] = int(root)
    else: return -1
  if cursor != int(length): return -1
  let required = 8 * q
  if output.isNil or capacity < csize_t(required): return -2

  var nodes: array[MaxNodes, Cluster]
  var used = 0
  var vertexLeaf: array[MaxN, int]
  var edgeLeaf: array[MaxE, int]
  for v in 0 ..< n:
    let id = append(nodes, used, VertexKind, -1, -1, v, values, edges)
    if id < 0: return -1
    vertexLeaf[v] = id
  var adj: array[MaxN, array[MaxN, bool]]
  var edgeCluster: array[MaxN, array[MaxN, int8]]
  for u in 0 ..< MaxN:
    for v in 0 ..< MaxN: edgeCluster[u][v] = -1
  for e in 0 ..< n - 1:
    let id = append(nodes, used, EdgeKind, edgeU[e], edgeV[e], e, values, edges)
    if id < 0: return -1
    edgeLeaf[e] = id
    adj[edgeU[e]][edgeV[e]] = true
    adj[edgeV[e]][edgeU[e]] = true
    edgeCluster[edgeU[e]][edgeV[e]] = int8(id)
    edgeCluster[edgeV[e]][edgeU[e]] = int8(id)
  var active: array[MaxN, bool]
  var branches: array[MaxN, array[MaxN, int8]]
  var branchCount: array[MaxN, int]
  for v in 0 ..< n: active[v] = true
  var activeCount = n
  while activeCount > 1:
    if activeCount == 2:
      var pair: array[2, int]
      var found = 0
      for v in 0 ..< n:
        if active[v]: pair[found] = v; inc found
      let x = pair[0]
      let y = pair[1]
      let local = makeRake(nodes, used, vertexLeaf[x], branches[x], branchCount[x], values, edges)
      if local < 0: return -1
      let branch = append(nodes, used, BranchKind, int(edgeCluster[x][y]), local, x, values, edges)
      if branch < 0 or branchCount[y] >= MaxN: return -1
      branches[y][branchCount[y]] = int8(branch)
      inc branchCount[y]
      adj[x][y] = false; adj[y][x] = false
      edgeCluster[x][y] = -1; edgeCluster[y][x] = -1
      active[x] = false
      dec activeCount
      break
    var leaves, leafNeighbor: array[MaxN, int]
    var leafCount = 0
    for v in 0 ..< n:
      if active[v]:
        var near: array[2, int]
        if neighborCount(adj, active, n, v, near) == 1:
          leaves[leafCount] = v
          leafNeighbor[leafCount] = near[0]
          inc leafCount
    for i in 0 ..< leafCount:
      let x = leaves[i]
      let y = leafNeighbor[i]
      let local = makeRake(nodes, used, vertexLeaf[x], branches[x], branchCount[x], values, edges)
      if local < 0: return -1
      let branch = append(nodes, used, BranchKind, int(edgeCluster[x][y]), local, x, values, edges)
      if branch < 0 or branchCount[y] >= MaxN: return -1
      branches[y][branchCount[y]] = int8(branch)
      inc branchCount[y]
    for i in 0 ..< leafCount:
      let x = leaves[i]
      let y = leafNeighbor[i]
      adj[x][y] = false; adj[y][x] = false
      edgeCluster[x][y] = -1; edgeCluster[y][x] = -1
      active[x] = false
      dec activeCount
    if activeCount <= 1: break
    var chosen: array[MaxN, bool]
    var compress: array[MaxN, int]
    var compressCount = 0
    for x in 0 ..< n:
      if active[x]:
        var near: array[2, int]
        if neighborCount(adj, active, n, x, near) != 2: continue
        if not chosen[near[0]] and not chosen[near[1]]:
          chosen[x] = true
          compress[compressCount] = x
          inc compressCount
    var px, py, pz: array[MaxN, int]
    var pc: array[MaxN, int]
    for i in 0 ..< compressCount:
      let x = compress[i]
      var near: array[2, int]
      discard neighborCount(adj, active, n, x, near)
      let y = near[0]
      let z = near[1]
      let local = makeRake(nodes, used, vertexLeaf[x], branches[x], branchCount[x], values, edges)
      if local < 0: return -1
      let attached = append(nodes, used, AttachKind, int(edgeCluster[y][x]), local, x, values, edges)
      if attached < 0: return -1
      let merged = append(nodes, used, CompressKind, attached, int(edgeCluster[x][z]), x, values, edges)
      if merged < 0: return -1
      px[i] = x; py[i] = y; pz[i] = z; pc[i] = merged
    for i in 0 ..< compressCount:
      let x = px[i]; let y = py[i]; let z = pz[i]
      adj[y][x] = false; adj[x][y] = false; adj[x][z] = false; adj[z][x] = false
      edgeCluster[y][x] = -1; edgeCluster[x][y] = -1; edgeCluster[x][z] = -1; edgeCluster[z][x] = -1
      active[x] = false
      dec activeCount
    for i in 0 ..< compressCount:
      let y = py[i]; let z = pz[i]
      adj[y][z] = true; adj[z][y] = true
      edgeCluster[y][z] = int8(pc[i]); edgeCluster[z][y] = int8(pc[i])
  var rootVertex = 0
  while not active[rootVertex]: inc rootVertex
  let root = makeRake(nodes, used, vertexLeaf[rootVertex], branches[rootVertex], branchCount[rootVertex], values, edges)
  if root < 0: return -1
  var answers: array[MaxQ, int64]
  for i in 0 ..< q:
    let item = opItem[i]
    var nodeId: int
    if opCode[i] == 0:
      values[item] = opFirst[i]
      nodeId = vertexLeaf[item]
      recalc(nodes, nodeId, values, edges)
    else:
      edges[item] = Affine(mul: opFirst[i], add: opSecond[i])
      nodeId = edgeLeaf[item]
      recalc(nodes, nodeId, values, edges)
    var ancestor = nodes[nodeId].parent
    while ancestor >= 0:
      recalc(nodes, ancestor, values, edges)
      ancestor = nodes[ancestor].parent
    answers[i] = query(nodes, root, vertexLeaf, opRoot[i], values)
    if answers[i] < 0: return -1
  for i in 0 ..< q: storeLe(output, 8 * i, answers[i])
  int64(required)
