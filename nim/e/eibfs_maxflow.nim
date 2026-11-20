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

proc eibfsMaxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "eibfs_maxflow".} =
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
