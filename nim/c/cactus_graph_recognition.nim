const MaxN = 32
const MaxM = 128
const MaxInput = 259
const MaxArcs = 256

proc cactusGraphRecognition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cactus_graph_recognition".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > MaxN or mValue < 0 or mValue > MaxM: return -1
  let n = int(nValue)
  let m = int(mValue)
  if int(length) != 2 + 2 * m: return -1

  var edgeSeen: array[32, array[32, bool]]
  var head: array[32, int]
  for u in 0 ..< n: head[u] = -1
  var arcTo, arcEdge, nextArc: array[256, int]
  var arcCount = 0
  for e in 0 ..< m:
    let uValue = input[2 + 2 * e]
    let vValue = input[3 + 2 * e]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    if edgeSeen[u][v]: return -1
    edgeSeen[u][v] = true
    edgeSeen[v][u] = true
    arcTo[arcCount] = v; arcEdge[arcCount] = e
    nextArc[arcCount] = head[u]; head[u] = arcCount; inc arcCount
    arcTo[arcCount] = u; arcEdge[arcCount] = e
    nextArc[arcCount] = head[v]; head[v] = arcCount; inc arcCount

  var state: array[32, int]
  var parent, parentEdge, depth, cursor, stack, cycleVertices: array[32, int]
  var cycleOf: array[128, int]
  var used: array[128, bool]
  for u in 0 ..< n: parent[u] = -1; parentEdge[u] = -1; cursor[u] = -1
  for e in 0 ..< m: cycleOf[e] = -1
  var cycles = 0
  var edgeCactus = true
  var vertexCactus = true

  for root in 0 ..< n:
    if not edgeCactus: break
    if state[root] != 0: continue
    var top = 1
    state[root] = 1; cursor[root] = head[root]; stack[0] = root
    while top > 0 and edgeCactus:
      let u = stack[top - 1]
      let arc = cursor[u]
      if arc < 0:
        state[u] = 2
        dec top
        continue
      cursor[u] = nextArc[arc]
      let e = arcEdge[arc]
      if used[e]: continue
      used[e] = true
      let v = arcTo[arc]
      if state[v] == 0:
        parent[v] = u; parentEdge[v] = e; depth[v] = depth[u] + 1
        state[v] = 1; cursor[v] = head[v]; stack[top] = v; inc top
      elif state[v] == 1 and depth[v] < depth[u]:
        var x = u
        while x != v:
          let treeEdge = parentEdge[x]
          if treeEdge < 0 or cycleOf[treeEdge] != -1:
            edgeCactus = false
            break
          x = parent[x]
        if not edgeCactus: break
        x = u
        inc cycleVertices[x]
        if cycleVertices[x] > 1: vertexCactus = false
        while x != v:
          let treeEdge = parentEdge[x]
          cycleOf[treeEdge] = cycles
          x = parent[x]
          inc cycleVertices[x]
          if cycleVertices[x] > 1: vertexCactus = false
        cycleOf[e] = cycles
        inc cycles
  if not edgeCactus: return 0
  int64(4 * cycles + (if vertexCactus: 2 else: 0) + 1)
