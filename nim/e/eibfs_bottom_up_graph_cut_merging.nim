## Clean-room bounded Excesses IBFS maximum flow.
const
  NMax = 8
  MMax = 24
  InputMax = 77
  FreeTree = 0
  STree = 1
  TTree = 2

type EibfsState = object
  n, source, sink: int
  forward: bool
  kind, parent: array[NMax, int]
  original, residual: array[NMax, array[NMax, int64]]
  balance, ds, dt: array[NMax, int64]
  dsMax, dtMax: int64
  orphaned: array[NMax, bool]
  events: int

proc root(s: EibfsState, vertex: int): int =
  var v = vertex
  for unused in 0 ..< s.n:
    if s.parent[v] < 0: return v
    v = s.parent[v]
  -1

proc bottleneck(s: EibfsState, vertex, kind: int): int64 =
  var v = vertex
  var answer = 2401'i64
  for unused in 0 ..< s.n:
    let p = s.parent[v]
    if p < 0: return answer
    if kind == STree: answer = min(answer, s.residual[p][v])
    else: answer = min(answer, s.residual[v][p])
    v = p
  0

proc push(s: var EibfsState, u, v: int, amount: int64) =
  s.residual[u][v] -= amount
  s.residual[v][u] += amount
  if u != s.source and u != s.sink: s.balance[u] -= amount
  if v != s.source and v != s.sink: s.balance[v] += amount

proc markOrphan(s: var EibfsState, v: int, queue: var array[512, int], tail: var int) =
  if not s.orphaned[v]:
    s.orphaned[v] = true
    queue[tail] = v
    inc tail

proc detach(s: var EibfsState, v, kind: int, queue: var array[512, int], tail: var int) =
  for child in 0 ..< s.n:
    if s.kind[child] == kind and s.parent[child] == v:
      s.parent[child] = -1
      s.markOrphan(child, queue, tail)

proc adopt(s: var EibfsState, v, kind: int, queue: var array[512, int], tail: var int) =
  let sinkSide = kind == TTree
  s.orphaned[v] = false
  let old = if sinkSide: s.dt[v] else: s.ds[v]
  for u in 0 ..< s.n:
    let capacity = if sinkSide: s.residual[v][u] else: s.residual[u][v]
    let labels = if sinkSide: s.dt else: s.ds
    if u != v and s.kind[u] == kind and capacity > 0 and labels[v] == labels[u] + 1:
      s.parent[v] = u
      return
  let frontier = if sinkSide: s.dtMax else: s.dsMax
  let subtract = if sinkSide: s.forward else: not s.forward
  let limit = frontier - (if subtract: 1 else: 0)
  var best = int64(4 * s.n)
  for u in 0 ..< s.n:
    let capacity = if sinkSide: s.residual[v][u] else: s.residual[u][v]
    let label = if sinkSide: s.dt[u] else: s.ds[u]
    if u != v and s.kind[u] == kind and capacity > 0 and label <= limit: best = min(best, label)
  var parent = -1
  for u in 0 ..< s.n:
    let capacity = if sinkSide: s.residual[v][u] else: s.residual[u][v]
    let label = if sinkSide: s.dt[u] else: s.ds[u]
    if u != v and s.kind[u] == kind and capacity > 0 and label == best:
      parent = u
      break
  if parent >= 0 and best + 1 > old:
    s.detach(v, kind, queue, tail)
    s.parent[v] = parent
    if sinkSide: s.dt[v] = best + 1
    else: s.ds[v] = best + 1
    return
  s.detach(v, kind, queue, tail)
  s.parent[v] = -1
  s.kind[v] = FreeTree
  if sinkSide and s.balance[v] > 0:
    s.kind[v] = STree
    s.ds[v] = s.dsMax + (if s.forward: 1 else: 0)
  elif not sinkSide and s.balance[v] < 0:
    s.kind[v] = TTree
    s.dt[v] = s.dtMax + (if s.forward: 0 else: 1)

proc repairOrphans(s: var EibfsState, kind: int, queue: var array[512, int], head: int, tail: var int) =
  var at = head
  while at < tail:
    let v = queue[at]
    inc at
    s.orphaned[v] = false
    if s.kind[v] == kind: s.adopt(v, kind, queue, tail)

proc drain(s: var EibfsState, v, kind: int) =
  let rootVertex = s.root(v)
  if rootVertex < 0: return
  var queue: array[512, int]
  var tail = 0
  var x = v
  while (if kind == TTree: s.balance[x] > 0 else: s.balance[x] < 0) and s.parent[x] >= 0:
    let p = s.parent[x]
    let cap = if kind == TTree: s.residual[x][p] else: s.residual[p][x]
    let need = if kind == TTree: s.balance[x] else: -s.balance[x]
    let amount = min(need, cap)
    if amount > 0:
      if kind == TTree: s.push(x, p, amount)
      else: s.push(p, x, amount)
    let after = if kind == TTree: s.balance[x] else: -s.balance[x]
    let remaining = if kind == TTree: s.residual[x][p] else: s.residual[p][x]
    if remaining == 0 and after >= 0:
      s.parent[x] = -1
      s.markOrphan(x, queue, tail)
      break
    if after == 0: break
    x = p
  if kind == TTree and rootVertex != s.sink and s.kind[rootVertex] == kind and s.balance[rootVertex] >= 0:
    s.parent[rootVertex] = -1
    s.markOrphan(rootVertex, queue, tail)
  elif kind == STree and rootVertex != s.source and s.kind[rootVertex] == kind and s.balance[rootVertex] <= 0:
    s.parent[rootVertex] = -1
    s.markOrphan(rootVertex, queue, tail)
  s.repairOrphans(kind, queue, 0, tail)

proc repair(s: var EibfsState) =
  while true:
    var found = false
    for v in 0 ..< s.n:
      if s.kind[v] == TTree and s.balance[v] > 0:
        s.drain(v, TTree)
        found = true
        break
    if found: continue
    for v in 0 ..< s.n:
      if s.kind[v] == STree and s.balance[v] < 0:
        s.drain(v, STree)
        found = true
        break
    if not found: return

proc augment(s: var EibfsState, v, w: int): bool =
  let rs = s.root(v)
  let rt = s.root(w)
  if rs < 0 or rt < 0 or s.residual[v][w] <= 0: return false
  let connector = s.residual[v][w]
  let bs = s.bottleneck(v, STree)
  let bt = s.bottleneck(w, TTree)
  var amount: int64
  if rs == s.source and rt == s.sink: amount = connector
  elif rs == s.source: amount = min(bs, connector)
  elif rt == s.sink: amount = min(connector, bt)
  else: amount = min(min(min(min(s.balance[rs], bs), connector), bt), -s.balance[rt])
  if amount <= 0: return false
  s.push(v, w, amount)
  s.repair()
  true

proc solve(s: var EibfsState): int64 =
  for phase in 0 ..< 4 * s.n + 4:
    var finished = false
    while true:
      var restart = false
      if s.forward:
        for v in 0 ..< s.n:
          if restart: break
          if s.kind[v] != STree or s.ds[v] != s.dsMax: continue
          for w in 0 ..< s.n:
            if s.residual[v][w] <= 0 or s.kind[w] == STree: continue
            if s.kind[w] == FreeTree:
              s.kind[w] = STree
              s.parent[w] = v
              s.ds[w] = s.dsMax + 1
            elif s.kind[w] == TTree and s.augment(v, w):
              inc s.events
              if s.events > 100_000: return -1
              restart = true
              break
        if not restart:
          var next = false
          for v in 0 ..< s.n:
            if s.kind[v] == STree and s.ds[v] == s.dsMax + 1: next = true
          if not next: finished = true
          else: inc s.dsMax
          break
      else:
        for w in 0 ..< s.n:
          if restart: break
          if s.kind[w] != TTree or s.dt[w] != s.dtMax: continue
          for v in 0 ..< s.n:
            if s.residual[v][w] <= 0 or s.kind[v] == TTree: continue
            if s.kind[v] == FreeTree:
              s.kind[v] = TTree
              s.parent[v] = w
              s.dt[v] = s.dtMax + 1
            elif s.kind[v] == STree and s.augment(v, w):
              inc s.events
              if s.events > 100_000: return -1
              restart = true
              break
        if not restart:
          var next = false
          for v in 0 ..< s.n:
            if s.kind[v] == TTree and s.dt[v] == s.dtMax + 1: next = true
          if not next: finished = true
          else: inc s.dtMax
          break
      if not restart: break
    if finished: break
    s.forward = not s.forward
  var reachable: array[NMax, bool]
  var queue: array[NMax, int]
  var head = 0
  var tail = 0
  for v in 0 ..< s.n:
    if s.kind[v] == STree:
      reachable[v] = true
      queue[tail] = v
      inc tail
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0 ..< s.n:
      if s.residual[u][v] > 0 and not reachable[v]:
        reachable[v] = true
        queue[tail] = v
        inc tail
  var cut = 0'i64
  for u in 0 ..< s.n:
    if reachable[u]:
      for v in 0 ..< s.n:
        if not reachable[v]: cut += s.original[u][v]
  cut

proc eibfsMaxflowFrame(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if input.isNil or length < 4 or length > InputMax: return -1
  let nv = input[0]
  let mv = input[1]
  let sv = input[2]
  let tv = input[3]
  if nv < 2 or nv > NMax or mv < 0 or mv > MMax or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv: return -1
  let (n, m, source, sink) = (int(nv), int(mv), int(sv), int(tv))
  if int(length) != 4 + 3 * m: return -1
  var s: EibfsState
  s.n = n
  s.source = source
  s.sink = sink
  s.forward = true
  for v in 0 ..< n: s.parent[v] = -1
  for e in 0 ..< m:
    let u = input[4 + 3 * e]
    let v = input[5 + 3 * e]
    let c = input[6 + 3 * e]
    if u < 0 or u >= nv or v < 0 or v >= nv or u == v or c < 0 or c > 100: return -1
    s.original[int(u)][int(v)] += c
    s.residual[int(u)][int(v)] += c
  s.kind[source] = STree
  s.kind[sink] = TTree
  s.solve()

proc peibfsFind(parent: array[4, int], blockId: int): int =
  var root = blockId
  for unused in 0 ..< 4:
    if parent[root] == root: return root
    root = parent[root]
  root

proc peibfsComponentFlow(n, m: int, active: array[4, bool],
                         blockIds: array[6, int], sourceCaps, sinkCaps: array[6, int64],
                         edgeU, edgeV: array[6, int], edgeUV, edgeVU: array[6, int64]): int64 =
  var local: array[6, int]
  var vertices: array[6, int]
  for v in 0 ..< n: local[v] = -1
  var k = 0
  for v in 0 ..< n:
    if active[blockIds[v]]:
      local[v] = k
      vertices[k] = v
      inc k
  var internalEdges = 0
  for e in 0 ..< m:
    if local[edgeU[e]] >= 0 and local[edgeV[e]] >= 0: inc internalEdges
  var frame: array[InputMax, int64]
  let source = k
  let sink = k + 1
  frame[0] = int64(k + 2)
  frame[1] = int64(2 * k + 2 * internalEdges)
  frame[2] = int64(source)
  frame[3] = int64(sink)
  var at = 4
  for i in 0 ..< k:
    let v = vertices[i]
    frame[at] = int64(source)
    frame[at + 1] = int64(i)
    frame[at + 2] = sourceCaps[v]
    at += 3
    frame[at] = int64(i)
    frame[at + 1] = int64(sink)
    frame[at + 2] = sinkCaps[v]
    at += 3
  for e in 0 ..< m:
    let u = edgeU[e]
    let v = edgeV[e]
    if local[u] >= 0 and local[v] >= 0:
      frame[at] = int64(local[u])
      frame[at + 1] = int64(local[v])
      frame[at + 2] = edgeUV[e]
      at += 3
      frame[at] = int64(local[v])
      frame[at + 1] = int64(local[u])
      frame[at + 2] = edgeVU[e]
      at += 3
  eibfsMaxflowFrame(cast[ptr UncheckedArray[int64]](addr frame[0]), csize_t(at))

proc eibfsBottomUpGraphCutMerging*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "eibfs_bottom_up_graph_cut_merging".} =
  if input.isNil or length < 3 or length > 46: return -1
  let nv, mv, bv = input[0], input[1], input[2]
  if nv < 2 or nv > 6 or mv < 0 or mv > 6 or bv < 1 or bv > 4 or bv > nv: return -1
  let n, m, blocks = int(nv), int(mv), int(bv)
  if int(length) != 3 + 3 * n + 4 * m: return -1
  var blockIds: array[6, int]
  var sourceCaps, sinkCaps: array[6, int64]
  var edgeU, edgeV: array[6, int]
  var edgeUV, edgeVU: array[6, int64]
  var present: array[4, bool]
  for v in 0 ..< n:
    let block = input[3 + v]
    let sc = input[3 + n + v]
    let tc = input[3 + 2 * n + v]
    if block < 0 or block >= bv or sc < 0 or sc > 7 or tc < 0 or tc > 7: return -1
    blockIds[v] = int(block)
    present[int(block)] = true
    sourceCaps[v] = sc
    sinkCaps[v] = tc
  for b in 0 ..< blocks:
    if not present[b]: return -1
  let edgesAt = 3 + 3 * n
  for e in 0 ..< m:
    let u, v = input[edgesAt + 4 * e], input[edgesAt + 4 * e + 1]
    let uv, vu = input[edgesAt + 4 * e + 2], input[edgesAt + 4 * e + 3]
    if u < 0 or u >= nv or v < 0 or v >= nv or u == v or uv < 0 or uv > 7 or vu < 0 or vu > 7: return -1
    edgeU[e], edgeV[e] = int(u), int(v)
    edgeUV[e], edgeVU[e] = uv, vu

  var tags: array[6, int]
  var componentFlow: array[4, int64]
  var active: array[4, bool]
  for b in 0 ..< blocks:
    var vertices: array[6, int]
    var local: array[6, int]
    for v in 0 ..< n: local[v] = -1
    var k = 0
    for v in 0 ..< n:
      if blockIds[v] == b:
        vertices[k] = v
        local[v] = k
        inc k
    var bestCost = high(int64)
    var bestMask = 0
    for mask in 0 ..< (1 shl k):
      var cost: int64 = 0
      for i in 0 ..< k:
        let v = vertices[i]
        if (mask and (1 shl i)) != 0: cost += sinkCaps[v]
        else: cost += sourceCaps[v]
      for e in 0 ..< m:
        let u, v = edgeU[e], edgeV[e]
        let ui, vi = local[u], local[v]
        if ui >= 0 and vi >= 0:
          let uSide = (mask and (1 shl ui)) != 0
          let vSide = (mask and (1 shl vi)) != 0
          if uSide and not vSide: cost += edgeUV[e]
          elif vSide and not uSide: cost += edgeVU[e]
      if cost < bestCost:
        bestCost = cost
        bestMask = mask
    for i in 0 ..< k:
      tags[vertices[i]] = if (bestMask and (1 shl i)) != 0: 1 else: 2
    active[b] = true
    componentFlow[b] = peibfsComponentFlow(n, m, active, blockIds, sourceCaps, sinkCaps, edgeU, edgeV, edgeUV, edgeVU)
    if componentFlow[b] < 0: return -1
    active[b] = false

  var pairA, pairB: array[6, int]
  var pairScore: array[6, int64]
  var pairCount = 0
  for e in 0 ..< m:
    let u, v = edgeU[e], edgeV[e]
    let a0, b0 = blockIds[u], blockIds[v]
    if a0 == b0 or (edgeUV[e] == 0 and edgeVU[e] == 0): continue
    let a, b = min(a0, b0), max(a0, b0)
    var found = -1
    for i in 0 ..< pairCount:
      if pairA[i] == a and pairB[i] == b: found = i
    if found < 0:
      found = pairCount
      inc pairCount
      pairA[found], pairB[found] = a, b
    if tags[u] != tags[v]:
      if edgeUV[e] > 0: inc pairScore[found]
      if edgeVU[e] > 0: inc pairScore[found]
  for i in 0 ..< pairCount:
    for j in i + 1 ..< pairCount:
      let precedes = pairScore[j] > pairScore[i] or
        (pairScore[j] == pairScore[i] and
          (pairA[j] < pairA[i] or (pairA[j] == pairA[i] and pairB[j] < pairB[i])))
      if precedes:
        swap(pairA[i], pairA[j])
        swap(pairB[i], pairB[j])
        swap(pairScore[i], pairScore[j])

  var parent: array[4, int]
  for b in 0 ..< blocks: parent[b] = b
  for i in 0 ..< pairCount:
    let rootA = peibfsFind(parent, pairA[i])
    let rootB = peibfsFind(parent, pairB[i])
    if rootA == rootB: continue
    let root = min(rootA, rootB)
    let other = max(rootA, rootB)
    parent[other] = root
    for b in 0 ..< blocks: active[b] = peibfsFind(parent, b) == root
    componentFlow[root] = peibfsComponentFlow(n, m, active, blockIds, sourceCaps, sinkCaps, edgeU, edgeV, edgeUV, edgeVU)
    if componentFlow[root] < 0: return -1
    componentFlow[other] = 0
  var answer: int64 = 0
  for b in 0 ..< blocks:
    if peibfsFind(parent, b) == b: answer += componentFlow[b]
  answer
