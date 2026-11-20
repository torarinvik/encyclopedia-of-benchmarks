const
  MaxN = 8
  MaxM = 18
  MaxF = 12
  MaxInput = 93
  FlowNodes = 2 * MaxN + 2
  States = 1 shl MaxN

proc thConnected(adj: array[MaxN, array[MaxN, bool]], n, removed: int): bool =
  var seen: array[MaxN, bool]
  var stack: array[MaxN, int]
  let start = if removed == 0: 1 else: 0
  var top = 1
  var count = 0
  seen[start] = true
  stack[0] = start
  while top > 0:
    dec top
    let u = stack[top]
    inc count
    for v in 0 ..< n:
      if v != removed and adj[u][v] and not seen[v]:
        seen[v] = true
        stack[top] = v
        inc top
  count == n - (if removed >= 0: 1 else: 0)

proc thThreeOuterPaths(adj: array[MaxN, array[MaxN, bool]],
                       outer: array[MaxN, bool], n, root: int): bool =
  var residual: array[FlowNodes, array[FlowNodes, int]]
  let source = 2 * n
  let sink = source + 1
  let nodes = sink + 1
  for v in 0 ..< n:
    if v != root: residual[2*v][2*v+1] = 1
  for u in 0 ..< n:
    for v in (u+1) ..< n:
      if not adj[u][v]: continue
      if u == root: inc residual[source][2*v]
      elif v == root: inc residual[source][2*u]
      else:
        inc residual[2*u+1][2*v]
        inc residual[2*v+1][2*u]
  for v in 0 ..< n:
    if outer[v] and v != root: inc residual[2*v+1][sink]
  for flow in 0 ..< 3:
    var parent: array[FlowNodes, int]
    var queue: array[FlowNodes, int]
    for v in 0 ..< nodes: parent[v] = -1
    parent[source] = source
    queue[0] = source
    var head = 0
    var tail = 1
    while head < tail and parent[sink] < 0:
      let u = queue[head]
      inc head
      for v in 0 ..< nodes:
        if residual[u][v] > 0 and parent[v] < 0:
          parent[v] = u
          queue[tail] = v
          inc tail
          if v == sink: break
    if parent[sink] < 0: return false
    var v = sink
    while v != source:
      let u = parent[v]
      dec residual[u][v]
      inc residual[v][u]
      v = u
  true

proc thConditionThree(inner: array[MaxN, array[MaxN, bool]],
                      degree: array[MaxN, int], n: int): bool =
  var maskSize: array[States, int]
  for mask in 1 ..< (1 shl n): maskSize[mask] = maskSize[mask shr 1] + (mask and 1)
  for start in 0 ..< n:
    var dp: array[States, array[MaxN, uint8]]
    for mask in 0 ..< States:
      for last in 0 ..< MaxN: dp[mask][last] = 255
    dp[1 shl start][start] = uint8(if degree[start] >= 3: 1 else: 0)
    for mask in 0 ..< (1 shl n):
      if (mask and (1 shl start)) == 0: continue
      for last in start ..< n:
        let used = dp[mask][last]
        if used == 255: continue
        if maskSize[mask] >= 3 and inner[last][start] and used < 3: return false
        for nxt in (start+1) ..< n:
          let bit = 1 shl nxt
          if (mask and bit) != 0 or not inner[last][nxt]: continue
          let candidate = used + uint8(if degree[nxt] >= 3: 1 else: 0)
          let nextMask = mask or bit
          if candidate < dp[nextMask][nxt]: dp[nextMask][nxt] = candidate
  true

proc thCompute(values: openArray[int64]): int64 =
  if values.len < 5 or values.len > MaxInput: return -1
  let n64, m64, f64, outer64, sides64 = values[0], values[1], values[2], values[3], values[4]
  if n64 < 3 or n64 > MaxN or m64 < n64 or m64 > MaxM or m64 > 3*n64-6 or
     f64 < 2 or f64 > MaxF or f64 != m64-n64+2 or outer64 < 0 or outer64 >= f64 or
     sides64 < 3 or sides64 > n64: return -1
  let n, m, f, outerId, sideCount = int(n64), int(m64), int(f64), int(outer64), int(sides64)
  var adj: array[MaxN, array[MaxN, bool]]
  var edgeU, edgeV: array[MaxM, int]
  var p = 5
  for e in 0 ..< m:
    if p + 2 > values.len: return -1
    let u64, v64 = values[p], values[p+1]
    p += 2
    if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
    let u, v = int(u64), int(v64)
    if adj[u][v] or (e > 0 and (u < edgeU[e-1] or (u == edgeU[e-1] and v <= edgeV[e-1]))): return -1
    adj[u][v] = true
    adj[v][u] = true
    edgeU[e] = u
    edgeV[e] = v
  var faces: array[MaxF, array[MaxN, int]]
  var widths: array[MaxF, int]
  var darts: array[MaxN, array[MaxN, int]]
  for face in 0 ..< f:
    if p >= values.len: return -1
    let width64 = values[p]
    inc p
    if width64 < 3 or width64 > n64 or p + int(width64) > values.len: return -1
    let width = int(width64)
    widths[face] = width
    var row: array[MaxN, bool]
    for i in 0 ..< width:
      let x64 = values[p]
      inc p
      if x64 < 0 or x64 >= n64 or row[int(x64)]: return -1
      let x = int(x64)
      row[x] = true
      faces[face][i] = x
    for i in 0 ..< width:
      let u = faces[face][i]
      let v = faces[face][(i+1) mod width]
      if not adj[u][v]: return -1
      inc darts[u][v]
  if p + sideCount != values.len: return -1
  var apex: array[MaxN, int]
  for i in 0 ..< sideCount:
    let position = values[p]
    inc p
    if position < 0 or position >= int64(widths[outerId]) or (i > 0 and position <= int64(apex[i-1])): return -1
    apex[i] = int(position)
  for e in 0 ..< m:
    if darts[edgeU[e]][edgeV[e]] != 1 or darts[edgeV[e]][edgeU[e]] != 1: return -1
  if not thConnected(adj, n, -1): return -1
  for v in 0 ..< n:
    if not thConnected(adj, n, v): return -1

  var linkAdj: array[MaxN, array[MaxN, array[MaxN, bool]]]
  var linkDegree: array[MaxN, array[MaxN, int]]
  for face in 0 ..< f:
    for i in 0 ..< widths[face]:
      let center = faces[face][i]
      let before = faces[face][(i+widths[face]-1) mod widths[face]]
      let after = faces[face][(i+1) mod widths[face]]
      if before == after: return -1
      linkAdj[center][before][after] = true
      linkAdj[center][after][before] = true
      inc linkDegree[center][before]
      inc linkDegree[center][after]
  for center in 0 ..< n:
    var seed = -1
    var incident = 0
    for v in 0 ..< n:
      if adj[center][v]:
        if linkDegree[center][v] != 2: return -1
        if seed < 0: seed = v
        inc incident
      elif linkDegree[center][v] != 0: return -1
    if seed < 0: return -1
    var seen: array[MaxN, bool]
    var stack: array[MaxN, int]
    var top = 1
    var reached = 0
    seen[seed] = true
    stack[0] = seed
    while top > 0:
      dec top
      let v = stack[top]
      inc reached
      for w in 0 ..< n:
        if linkAdj[center][v][w] and not seen[w]:
          seen[w] = true
          stack[top] = w
          inc top
    if reached != incident: return -1

  var outerV: array[MaxN, bool]
  var outerE: array[MaxN, array[MaxN, bool]]
  for i in 0 ..< widths[outerId]:
    let u = faces[outerId][i]
    let v = faces[outerId][(i+1) mod widths[outerId]]
    outerV[u] = true
    outerE[u][v] = true
    outerE[v][u] = true
  var faceA, faceB, faceUse: array[MaxM, int]
  for face in 0 ..< f:
    for i in 0 ..< widths[face]:
      let u = faces[face][i]
      let v = faces[face][(i+1) mod widths[face]]
      let lo = min(u,v)
      let hi = max(u,v)
      var found = -1
      for e in 0 ..< m:
        if edgeU[e] == lo and edgeV[e] == hi: found = e; break
      if found < 0 or faceUse[found] >= 2: return -1
      if faceUse[found] == 0: faceA[found] = face else: faceB[found] = face
      inc faceUse[found]
  for e in 0 ..< m:
    if faceUse[e] != 2 or faceA[e] == faceB[e]: return -1
  var sides: array[MaxN, array[MaxN, bool]]
  for s in 0 ..< sideCount:
    var at = apex[s]
    let finish = apex[(s+1) mod sideCount]
    while true:
      sides[s][faces[outerId][at]] = true
      if at == finish: break
      at = (at+1) mod widths[outerId]
  var degree: array[MaxN, int]
  for u in 0 ..< n:
    for v in 0 ..< n:
      if adj[u][v]: inc degree[u]
  for root in 0 ..< n:
    if not outerV[root] and degree[root] >= 3 and not thThreeOuterPaths(adj, outerV, n, root): return 0
  var seenInner: array[MaxN, bool]
  for seed in 0 ..< n:
    if outerV[seed] or seenInner[seed]: continue
    var border: array[MaxN, bool]
    var stack: array[MaxN, int]
    var top = 1
    seenInner[seed] = true
    stack[0] = seed
    while top > 0:
      dec top
      let u = stack[top]
      for v in 0 ..< n:
        if not adj[u][v]: continue
        if outerV[v]: border[v] = true
        elif not seenInner[v]: seenInner[v] = true; stack[top] = v; inc top
    for s in 0 ..< sideCount:
      var nonempty = false
      var contained = true
      for v in 0 ..< n:
        if border[v]: nonempty = true; if not sides[s][v]: contained = false
      if nonempty and contained: return 0
  for e in 0 ..< m:
    let u = edgeU[e]
    let v = edgeV[e]
    if not outerE[u][v]:
      for s in 0 ..< sideCount:
        if sides[s][u] and sides[s][v]: return 0
  var inner: array[MaxN, array[MaxN, bool]]
  for e in 0 ..< m:
    let u = edgeU[e]
    let v = edgeV[e]
    if not outerE[u][v]: inner[u][v] = true; inner[v][u] = true
  if thConditionThree(inner, degree, n): 1 else: 0

proc thomassen_convex_drawing_extendibility*(input: ptr UncheckedArray[int64],
    inputLength: csize_t): int64 {.cdecl, exportc: "thomassen_convex_drawing_extendibility".} =
  if input.isNil or inputLength < 5 or inputLength > MaxInput.csize_t: return -1
  var packed: array[MaxInput, int64]
  for i in 0 ..< int(inputLength): packed[i] = input[csize_t(i)]
  thCompute(packed.toOpenArray(0, int(inputLength)-1))
