const MaxN = 32
const MaxM = 96
const MaxD = 192

type
  Interval = object
    low, high: int
  Conflict = object
    left, right: Interval
  State = object
    n, m: int
    edgeOf, adj, rotation: array[MaxN, array[MaxN, int]]
    degree, height, parent, outCount, rotationCount, leftRef, rightRef, roots: array[MaxN, int]
    eu, ev, tail, head, low, low2, nest, reference, side, lowEdge, bottom: array[MaxM, int]
    out: array[MaxN, array[MaxN, int]]
    stack: array[MaxD, Conflict]
    stackLen, rootCount: int

proc emptyInterval(): Interval = Interval(low: -1, high: -1)
proc emptyConflict(): Conflict = Conflict(left: emptyInterval(), right: emptyInterval())
proc isEmpty(a: Interval): bool = a.low < 0
proc swapIntervals(p: var Conflict) =
  let t = p.left
  p.left = p.right
  p.right = t

proc updateParent(s: var State, back, pe: int) =
  if pe < 0: return
  if s.low[back] < s.low[pe]:
    s.low2[pe] = min(s.low[pe], s.low2[back])
    s.low[pe] = s.low[back]
  elif s.low[back] > s.low[pe]:
    s.low2[pe] = min(s.low2[pe], s.low[back])
  else:
    s.low2[pe] = min(s.low2[pe], s.low2[back])

proc orient(s: var State, v: int) =
  let pe = s.parent[v]
  for i in 0 ..< s.degree[v]:
    let w = s.adj[v][i]
    let e = s.edgeOf[v][w]
    if s.tail[e] >= 0: continue
    s.tail[e] = v
    s.head[e] = w
    s.low[e] = s.height[v]
    s.low2[e] = s.height[v]
    if s.height[w] < 0:
      s.parent[w] = e
      s.height[w] = s.height[v] + 1
      orient(s, w)
      s.nest[e] = 2 * s.low[e] + ord(s.low2[e] < s.height[v])
    else:
      s.low[e] = s.height[w]
      s.low2[e] = s.height[v]
      s.nest[e] = 2 * s.low[e] + ord(s.low2[e] < s.height[v])
    updateParent(s, e, pe)

proc intervalConflicts(s: State, a: Interval, e: int): bool =
  a.high >= 0 and s.low[a.high] > s.low[e]

proc pairLowest(s: State, p: Conflict): int =
  let a = if p.left.low >= 0: s.low[p.left.low] else: 1000
  let b = if p.right.low >= 0: s.low[p.right.low] else: 1000
  min(a, b)

proc addConstraints(s: var State, ei, pe: int): bool =
  var p = emptyConflict()
  while true:
    if s.stackLen == 0: return false
    dec s.stackLen
    var q = s.stack[s.stackLen]
    if not isEmpty(q.left): swapIntervals(q)
    if not isEmpty(q.left): return false
    if s.low[q.right.low] > s.low[pe]:
      if isEmpty(p.right): p.right = q.right
      else:
        s.reference[p.right.low] = q.right.high
        p.right.low = q.right.low
    else:
      s.reference[q.right.low] = s.lowEdge[pe]
    if s.stackLen - 1 == s.bottom[ei]: break
  while s.stackLen > 0 and (intervalConflicts(s, s.stack[s.stackLen-1].left, ei) or
      intervalConflicts(s, s.stack[s.stackLen-1].right, ei)):
    dec s.stackLen
    var q = s.stack[s.stackLen]
    if intervalConflicts(s, q.right, ei): swapIntervals(q)
    if intervalConflicts(s, q.right, ei): return false
    if p.right.low >= 0: s.reference[p.right.low] = q.right.high
    if q.right.low >= 0: p.right.low = q.right.low
    if isEmpty(p.left): p.left = q.left
    else:
      s.reference[p.left.low] = q.left.high
      p.left.low = q.left.low
  if not isEmpty(p.left) or not isEmpty(p.right):
    s.stack[s.stackLen] = p
    inc s.stackLen
  true

proc removeReturns(s: var State, e: int) =
  let u = s.tail[e]
  while s.stackLen > 0 and pairLowest(s, s.stack[s.stackLen-1]) == s.height[u]:
    dec s.stackLen
    let p = s.stack[s.stackLen]
    if p.left.low >= 0: s.side[p.left.low] = -1
  if s.stackLen > 0:
    dec s.stackLen
    var p = s.stack[s.stackLen]
    while p.left.high >= 0 and s.head[p.left.high] == u: p.left.high = s.reference[p.left.high]
    if p.left.high < 0 and p.left.low >= 0:
      s.reference[p.left.low] = p.right.low
      s.side[p.left.low] = -1
      p.left.low = -1
    while p.right.high >= 0 and s.head[p.right.high] == u: p.right.high = s.reference[p.right.high]
    if p.right.high < 0 and p.right.low >= 0:
      s.reference[p.right.low] = p.left.low
      s.side[p.right.low] = -1
      p.right.low = -1
    s.stack[s.stackLen] = p
    inc s.stackLen
  if s.low[e] < s.height[u] and s.stackLen > 0:
    let p = s.stack[s.stackLen-1]
    let lh = p.left.high
    let rh = p.right.high
    s.reference[e] = if lh >= 0 and (rh < 0 or s.low[lh] > s.low[rh]): lh else: rh

proc testDfs(s: var State, v: int): bool =
  let pe = s.parent[v]
  for i in 0 ..< s.outCount[v]:
    let e = s.out[v][i]
    let w = s.head[e]
    s.bottom[e] = s.stackLen - 1
    if s.parent[w] == e:
      if not testDfs(s, w): return false
    else:
      s.lowEdge[e] = e
      var p = emptyConflict()
      p.right = Interval(low: e, high: e)
      s.stack[s.stackLen] = p
      inc s.stackLen
      if s.low[e] < s.height[v]:
        if i == 0:
          if pe >= 0: s.lowEdge[pe] = e
        elif pe < 0 or not addConstraints(s, e, pe):
          return false
  if pe >= 0: removeReturns(s, pe)
  true

proc resolveSide(s: var State, e: int): int =
  if s.reference[e] >= 0:
    let r = s.reference[e]
    s.side[e] *= resolveSide(s, r)
    s.reference[e] = -1
  s.side[e]

proc edgeBefore(s: State, a, b: int, depth: array[MaxM, int]): bool =
  depth[a] < depth[b] or (depth[a] == depth[b] and s.head[a] < s.head[b])

proc insertNeighbor(s: var State, v, w, reference: int, after: bool) =
  let count = s.rotationCount[v]
  var pos = 0
  if count > 0 and reference >= 0:
    while pos < count and s.rotation[v][pos] != reference: inc pos
    if pos == count: pos = count
    elif after: pos = (pos + 1) mod count
  var i = count
  while i > pos:
    s.rotation[v][i] = s.rotation[v][i-1]
    dec i
  s.rotation[v][pos] = w
  s.rotationCount[v] = count + 1

proc embed(s: var State, v: int) =
  for i in 0 ..< s.outCount[v]:
    let e = s.out[v][i]
    let w = s.head[e]
    if s.parent[w] == e:
      insertNeighbor(s, w, v, -1, false)
      s.leftRef[v] = w
      s.rightRef[v] = w
      embed(s, w)
    elif s.side[e] == 1:
      insertNeighbor(s, w, v, s.rightRef[w], true)
    else:
      insertNeighbor(s, w, v, s.leftRef[w], false)
      s.leftRef[w] = v

proc planar_embedding_lr*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 195: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or length != csize_t(2 + 2*m64): return -1
  var s: State
  s.n = int(n64)
  s.m = int(m64)
  for v in 0 ..< s.n:
    s.height[v] = -1
    s.parent[v] = -1
    s.leftRef[v] = -1
    s.rightRef[v] = -1
    for w in 0 ..< s.n: s.edgeOf[v][w] = -1
  for e in 0 ..< s.m:
    s.tail[e] = -1; s.head[e] = -1; s.reference[e] = -1; s.side[e] = 1; s.lowEdge[e] = -1; s.bottom[e] = -1
    let u64 = input[2+2*e]
    let v64 = input[3+2*e]
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if s.edgeOf[u][v] >= 0: return -1
    s.edgeOf[u][v] = e; s.edgeOf[v][u] = e
    s.eu[e] = u; s.ev[e] = v
  for v in 0 ..< s.n:
    for w in 0 ..< s.n:
      if s.edgeOf[v][w] >= 0:
        s.adj[v][s.degree[v]] = w
        inc s.degree[v]
  for root in 0 ..< s.n:
    if s.height[root] < 0:
      s.height[root] = 0
      s.roots[s.rootCount] = root
      inc s.rootCount
      orient(s, root)
  for e in 0 ..< s.m:
    let v = s.tail[e]
    s.out[v][s.outCount[v]] = e
    inc s.outCount[v]
  for v in 0 ..< s.n:
    for i in 1 ..< s.outCount[v]:
      let e = s.out[v][i]
      var j = i
      while j > 0 and edgeBefore(s, e, s.out[v][j-1], s.nest):
        s.out[v][j] = s.out[v][j-1]
        dec j
      s.out[v][j] = e
  var planar = true
  for i in 0 ..< s.rootCount:
    if not testDfs(s, s.roots[i]):
      planar = false
      break
  if output == nil: return -2
  if not planar:
    if capacity < 1: return -2
    output[0] = 0
    return 1
  var depth: array[MaxM, int]
  for e in 0 ..< s.m: depth[e] = s.nest[e] * resolveSide(s, e)
  for v in 0 ..< s.n:
    for i in 1 ..< s.outCount[v]:
      let e = s.out[v][i]
      var j = i
      while j > 0 and edgeBefore(s, e, s.out[v][j-1], depth):
        s.out[v][j] = s.out[v][j-1]
        dec j
      s.out[v][j] = e
  for v in 0 ..< s.n:
    for i in 0 ..< s.outCount[v]:
      s.rotation[v][s.rotationCount[v]] = s.head[s.out[v][i]]
      inc s.rotationCount[v]
  for i in 0 ..< s.rootCount: embed(s, s.roots[i])
  let needed = 1 + 2*s.m
  if capacity < csize_t(needed): return -2
  output[0] = 1
  var at = 1
  for v in 0 ..< s.n:
    for i in 0 ..< s.rotationCount[v]:
      output[at] = uint8(s.rotation[v][i])
      inc at
  int64(needed)
