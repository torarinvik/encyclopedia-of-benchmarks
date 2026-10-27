type Edge = object
  u, v: int
  w: int64

const N = 4

proc putI64(outp: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc root(p: var array[N, int], x0: int): int =
  var x = x0
  while p[x] != x:
    p[x] = p[p[x]]
    x = p[x]
  x

proc unite(p: var array[N, int], a, b: int): bool =
  let ra = root(p, a)
  let rb = root(p, b)
  if ra == rb: return false
  p[rb] = ra
  true

proc groupCount(n: int, mask: int64, h: array[N, array[N, bool]]): int =
  var p: array[N, int]
  for i in 0 ..< N: p[i] = i
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if h[i][j]: discard unite(p, i, j)
  var seen: array[N, bool]
  for i in 0 ..< n:
    if (mask and (1'i64 shl i)) != 0:
      let r = root(p, i)
      if not seen[r]: seen[r] = true; inc result

proc mstMetric(n: int, mask: int64, w: array[N, array[N, int64]]): int64 =
  var verts: seq[int] = @[]
  for i in 0 ..< n:
    if (mask and (1'i64 shl i)) != 0: verts.add(i)
  if verts.len <= 1: return 0
  var used: array[N, bool]
  var best: array[N, int64]
  for i in 0 ..< N: best[i] = high(int64)
  used[verts[0]] = true
  for v in verts: best[v] = w[verts[0]][v]
  for step in 1 ..< verts.len:
    var pick = -1
    for v in verts:
      if not used[v] and (pick < 0 or best[v] < best[pick] or (best[v] == best[pick] and v < pick)): pick = v
    result += best[pick]
    used[pick] = true
    for v in verts:
      if not used[v] and w[pick][v] < best[v]: best[v] = w[pick][v]

proc lessEdge(a, b: Edge): bool =
  a.w < b.w or (a.w == b.w and (a.u < b.u or (a.u == b.u and a.v < b.v)))

proc mstH(n: int, w: array[N, array[N, int64]], h: array[N, array[N, bool]]): tuple[cost: int64, edges: seq[Edge]] =
  var es: seq[Edge] = @[]
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if h[i][j]: es.add(Edge(u: i, v: j, w: w[i][j]))
  for i in 1 ..< es.len:
    let x = es[i]
    var j = i
    while j > 0 and lessEdge(x, es[j - 1]): es[j] = es[j - 1]; dec j
    es[j] = x
  var p: array[N, int]
  for i in 0 ..< N: p[i] = i
  for e in es:
    if unite(p, e.u, e.v): result.cost += e.w; result.edges.add(e)

proc contractedMst(n: int, mask: int64, w: array[N, array[N, int64]], h: array[N, array[N, bool]]): int64 =
  var d = w
  var p: array[N, int]
  for i in 0 ..< N: p[i] = i
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if h[i][j]: d[i][j] = 0; d[j][i] = 0; discard unite(p, i, j)
  for k in 0 ..< n:
    for i in 0 ..< n:
      for j in 0 ..< n:
        if d[i][j] > d[i][k] + d[k][j]: d[i][j] = d[i][k] + d[k][j]
  var roots: seq[int] = @[]
  for v in 0 ..< n:
    if (mask and (1'i64 shl v)) != 0:
      let r = root(p, v)
      if r notin roots: roots.add(r)
  if roots.len <= 1: return 0
  var q: array[N, array[N, int64]]
  for a in 0 ..< roots.len:
    for b in a + 1 ..< roots.len:
      var best = high(int64)
      for u in 0 ..< n:
        if root(p, u) == roots[a]:
          for v in 0 ..< n:
            if root(p, v) == roots[b] and d[u][v] < best: best = d[u][v]
      q[a][b] = best; q[b][a] = best
  var used: array[N, bool]
  var best: array[N, int64]
  for i in 0 ..< N: best[i] = high(int64)
  used[0] = true
  for j in 1 ..< roots.len: best[j] = q[0][j]
  for step in 1 ..< roots.len:
    var pick = -1
    for v in 0 ..< roots.len:
      if not used[v] and (pick < 0 or best[v] < best[pick] or (best[v] == best[pick] and v < pick)): pick = v
    result += best[pick]; used[pick] = true
    for v in 0 ..< roots.len:
      if not used[v] and q[pick][v] < best[v]: best[v] = q[pick][v]

proc steiner_tree_gain_greedy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 4 or length > 37: return -1
  let n0 = input[0]; let mask = input[1]; let count0 = input[2]
  if n0 < 2 or n0 > 4 or mask <= 0 or (mask shr int(n0)) != 0 or count0 < 1 or count0 > 4: return -1
  let n = int(n0); let count = int(count0)
  var terminals = 0
  for i in 0 ..< n: if (mask and (1'i64 shl i)) != 0: inc terminals
  if terminals < 2: return -1
  var w: array[N, array[N, int64]]
  var at = 3
  for i in 0 ..< n:
    for j in i + 1 ..< n:
      if at >= int(length) or input[at] < 0 or input[at] > 1000: return -1
      w[i][j] = input[at]; w[j][i] = input[at]; inc at
  for i in 0 ..< n:
    for j in 0 ..< n:
      for k in 0 ..< n: if w[i][j] > w[i][k] + w[k][j]: return -1
  var family: array[4, seq[tuple[u, v: int]]]
  var familyH: array[N, array[N, bool]]
  for c in 0 ..< count:
    if at >= int(length): return -1
    let ec0 = input[at]; inc at
    if ec0 < 1 or ec0 > n0 - 1 or at + 2 * int(ec0) > int(length): return -1
    var p: array[N, int]; var degree: array[N, int]
    for i in 0 ..< N: p[i] = i
    for e in 0 ..< int(ec0):
      let u0 = input[at]; let v0 = input[at + 1]; at += 2
      if u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0: return -1
      let u = int(u0); let v = int(v0)
      if (min(u,v),max(u,v)) in family[c] or not unite(p,u,v): return -1
      family[c].add((min(u,v),max(u,v))); familyH[u][v] = true; familyH[v][u] = true
      inc degree[u]; inc degree[v]
    var verts: seq[int] = @[]; var leaves = 0
    for v in 0 ..< n:
      if degree[v] > 0:
        verts.add(v)
        if degree[v] == 1:
          if (mask and (1'i64 shl v)) == 0: return -1
          inc leaves
        elif (mask and (1'i64 shl v)) != 0: return -1
    if verts.len != int(ec0)+1 or leaves < 2 or leaves > 3: return -1
    for v in verts: if root(p,v) != root(p,verts[0]): return -1
  if at != int(length) or groupCount(n,mask,familyH) != 1: return -1
  let baseline = mstMetric(n,mask,w)
  var h: array[N,array[N,bool]]
  var selected: array[4,bool]
  while groupCount(n,mask,h) > 1:
    let before = groupCount(n,mask,h)
    var best = -1; var bestGain = low(int64)
    for c in 0 ..< count:
      if selected[c]: continue
      var trial = h
      for e in family[c]: trial[e.u][e.v] = true; trial[e.v][e.u] = true
      if groupCount(n,mask,trial) >= before: continue
      let mh = mstH(n,w,trial).cost
      let gain = baseline - contractedMst(n,mask,w,trial) - mh
      if best < 0 or gain > bestGain: best = c; bestGain = gain
    if best < 0: return -1
    selected[best] = true
    for e in family[best]: h[e.u][e.v] = true; h[e.v][e.u] = true
  let tree = mstH(n,w,h)
  let bytes = 8 * (3 + 2 * tree.edges.len)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output,0,1); putI64(output,1,tree.cost); putI64(output,2,int64(tree.edges.len))
  for i,e in tree.edges: putI64(output,3+2*i,int64(e.u)); putI64(output,4+2*i,int64(e.v))
  int64(bytes)
