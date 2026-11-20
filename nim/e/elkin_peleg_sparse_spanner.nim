const MaxN = 20
const MaxM = 190
const MaxInput = 383
const Inf = 1000

type
  Cluster = object
    center, radius: int
    members: array[MaxN, bool]
    tree: array[MaxM, bool]
  Context = object
    n, m: int
    adjacent: array[MaxN, array[MaxN, bool]]
    edgeIndex: array[MaxN, array[MaxN, int]]
    distance: array[MaxN, array[MaxN, int]]

proc edgeId(c: Context, a, b: int): int =
  if a < b: c.edgeIndex[a][b] else: c.edgeIndex[b][a]

proc bfs(c: Context, source: int, allowed: ptr array[MaxN, bool],
         parent, distance: var array[MaxN, int]): int =
  var queue: array[MaxN, int]
  var head = 0
  var tail = 0
  for v in 0..<c.n:
    parent[v] = -1
    distance[v] = Inf
  queue[tail] = source
  inc tail
  distance[source] = 0
  while head < tail:
    let u = queue[head]
    inc head
    for v in 0..<c.n:
      if c.adjacent[u][v] and (allowed == nil or allowed[][v]) and distance[v] == Inf:
        distance[v] = distance[u] + 1
        parent[v] = u
        queue[tail] = v
        inc tail
  var radius = 0
  for v in 0..<c.n:
    if (allowed == nil or allowed[][v]) and distance[v] > radius: radius = distance[v]
  radius

proc tree(c: Context, allowed: array[MaxN, bool], root: int,
          result: var array[MaxM, bool]): int =
  var parent, distance: array[MaxN, int]
  let radius = bfs(c, root, unsafeAddr allowed, parent, distance)
  for v in 0..<c.n:
    if allowed[v] and v != root:
      let e = c.edgeId(v, parent[v])
      if e >= 0: result[e] = true
  radius

proc setDistance(c: Context, left, right: array[MaxN, bool]): int =
  var best = Inf
  for u in 0..<c.n:
    if left[u]:
      for v in 0..<c.n:
        if right[v] and c.distance[u][v] < best: best = c.distance[u][v]
  best

proc clusterBefore(a, b: Cluster, n: int): bool =
  if a.center != b.center: return a.center < b.center
  for v in 0..<n:
    if a.members[v] != b.members[v]: return a.members[v]
  false

proc connector(c: Context, left, right: array[MaxN, bool], result: var array[MaxM, bool]) =
  var bestDistance = Inf
  var bestLength = 0
  var bestPath: array[MaxN, int]
  var haveBest = false
  for source in 0..<c.n:
    if not left[source]: continue
    var parent, distance: array[MaxN, int]
    discard bfs(c, source, nil, parent, distance)
    for target in 0..<c.n:
      if not right[target] or distance[target] == Inf or distance[target] > bestDistance: continue
      var reversed: array[MaxN, int]
      var length = 0
      var v = target
      while v >= 0 and length < MaxN:
        reversed[length] = v
        inc length
        if v == source: break
        v = parent[v]
      if length == 0 or reversed[length - 1] != source: continue
      var earlier = not haveBest or distance[target] < bestDistance
      if not earlier and distance[target] == bestDistance:
        for i in 0..<length:
          let candidate = reversed[length - 1 - i]
          if candidate != bestPath[i]:
            earlier = candidate < bestPath[i]
            break
      if earlier:
        haveBest = true
        bestDistance = distance[target]
        bestLength = length
        for i in 0..<length: bestPath[i] = reversed[length - 1 - i]
  for i in 1..<bestLength:
    let e = c.edgeId(bestPath[i - 1], bestPath[i])
    if e >= 0: result[e] = true

proc sigma(n: int): int =
  result = 1
  while result * result * result * result < n: inc result

proc supercluster(c: Context, input: array[MaxN, Cluster], count, threshold, delta: int,
                  output: var array[MaxN, Cluster], outputCount: var int,
                  chosen: var array[MaxM, bool]) =
  var active: array[MaxN, bool]
  for i in 0..<count: active[i] = true
  outputCount = 0
  while true:
    var best = -1
    var neighborhoods: array[MaxN, array[MaxN, bool]]
    for i in 0..<count:
      if not active[i]: continue
      var close = 0
      for j in 0..<count:
        if active[j] and c.setDistance(input[i].members, input[j].members) <= delta:
          neighborhoods[i][j] = true
          inc close
      if close >= threshold and (best < 0 or clusterBefore(input[i], input[best], c.n)): best = i
    if best < 0: break
    var merged: Cluster
    merged.center = input[best].center
    for j in 0..<count:
      if not neighborhoods[best][j]: continue
      active[j] = false
      for v in 0..<c.n: merged.members[v] = merged.members[v] or input[j].members[v]
      for e in 0..<c.m: merged.tree[e] = merged.tree[e] or input[j].tree[e]
      if j != best:
        var path: array[MaxM, bool]
        c.connector(input[best].members, input[j].members, path)
        for e in 0..<c.m: merged.tree[e] = merged.tree[e] or path[e]
    for e in 0..<c.m: chosen[e] = chosen[e] or merged.tree[e]
    output[outputCount] = merged
    inc outputCount
  var remaining: array[MaxN, int]
  var remainCount = 0
  for i in 0..<count:
    if active[i]: remaining[remainCount] = i; inc remainCount
  for i in 1..<remainCount:
    let key = remaining[i]
    var j = i
    while j > 0 and clusterBefore(input[key], input[remaining[j - 1]], c.n):
      remaining[j] = remaining[j - 1]
      dec j
    remaining[j] = key
  for i in 0..<remainCount:
    for j in i + 1..<remainCount:
      let a = input[remaining[i]]
      let b = input[remaining[j]]
      if c.setDistance(a.members, b.members) <= delta: c.connector(a.members, b.members, chosen)

proc construct(c: var Context): array[MaxM, bool] =
  for s in 0..<c.n:
    var parent, distance: array[MaxN, int]
    discard bfs(c, s, nil, parent, distance)
    for v in 0..<c.n: c.distance[s][v] = distance[v]
  var chosen: array[MaxM, bool]
  var uncovered: array[MaxN, bool]
  for v in 0..<c.n: uncovered[v] = true
  var ground: array[MaxN, Cluster]
  var groundCount = 0
  while true:
    var root = -1
    for v in 0..<c.n:
      if uncovered[v]: root = v; break
    if root < 0: break
    var members: array[MaxN, bool]
    members[root] = true
    var size = 1
    while true:
      var shell: array[MaxN, bool]
      var shellSize = 0
      for v in 0..<c.n:
        shell[v] = members[v]
        if not shell[v] and uncovered[v]:
          for u in 0..<c.n:
            if members[u] and c.adjacent[u][v]: shell[v] = true; break
        if shell[v]: inc shellSize
      let size4 = size * size * size * size
      let shell4 = shellSize * shellSize * shellSize * shellSize
      if shellSize == size or shell4 < c.n * size4: break
      for v in 0..<c.n:
        if shell[v] and not members[v]: members[v] = true; inc size
    var shell: array[MaxN, bool]
    for v in 0..<c.n:
      shell[v] = members[v]
      if not shell[v] and uncovered[v]:
        for u in 0..<c.n:
          if members[u] and c.adjacent[u][v]: shell[v] = true; break
    var cluster: Cluster
    cluster.center = root
    cluster.members = members
    cluster.radius = c.tree(members, root, cluster.tree)
    var shellTree: array[MaxM, bool]
    discard c.tree(shell, root, shellTree)
    for e in 0..<c.m: chosen[e] = chosen[e] or shellTree[e]
    ground[groundCount] = cluster
    inc groundCount
    for v in 0..<c.n:
      if members[v]: uncovered[v] = false
  var level, supers: array[MaxN, Cluster]
  var levelCount = 0
  for i in 0..<groundCount:
    if ground[i].radius == 1: level[levelCount] = ground[i]; inc levelCount
  var superCount = 0
  c.supercluster(level, levelCount, sigma(c.n), 16, supers, superCount, chosen)
  var finalClusters: array[MaxN, Cluster]
  var finalCount = 0
  for i in 0..<superCount: finalClusters[finalCount] = supers[i]; inc finalCount
  for i in 0..<groundCount:
    if ground[i].radius == 2 or ground[i].radius == 3:
      finalClusters[finalCount] = ground[i]; inc finalCount
  for i in 1..<finalCount:
    let key = finalClusters[i]
    var j = i
    while j > 0 and clusterBefore(key, finalClusters[j - 1], c.n):
      finalClusters[j] = finalClusters[j - 1]
      dec j
    finalClusters[j] = key
  for i in 0..<finalCount:
    for j in i + 1..<finalCount:
      if c.setDistance(finalClusters[i].members, finalClusters[j].members) <= 128:
        c.connector(finalClusters[i].members, finalClusters[j].members, chosen)
  chosen

proc elkinPelegSparseSpanner*(a: ptr UncheckedArray[int64], length: csize_t,
                              output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "elkin_peleg_sparse_spanner".} =
  if a == nil or length < 2 or length > MaxInput: return -1
  let n64 = a[0]
  let m64 = a[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or length != csize_t(2 + 2 * m64): return -1
  var c: Context
  c.n = int(n64)
  c.m = int(m64)
  for u in 0..<MaxN:
    for v in 0..<MaxN: c.edgeIndex[u][v] = -1
  for e in 0..<c.m:
    let u64 = a[2 + 2 * e]
    let v64 = a[3 + 2 * e]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if c.edgeIndex[u][v] >= 0: return -1
    c.edgeIndex[u][v] = e
    c.edgeIndex[v][u] = e
    c.adjacent[u][v] = true
    c.adjacent[v][u] = true
  if output == nil or capacity < csize_t(c.m): return -2
  let chosen = construct(c)
  for e in 0..<c.m: output[e] = (if chosen[e]: 1'u8 else: 0'u8)
  int64(c.m)
