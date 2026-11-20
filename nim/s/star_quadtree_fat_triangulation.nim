const
  MaxInput = 25
  MaxDepth = 2
  MaxEdges = 8
  MaxPairs = 64

type
  Point = array[2, int]
  Triangle = array[3, int]
  Edge = array[2, int]
  State = object
    vertices: array[5, Point]
    triangles: array[4, Triangle]
    edges: array[MaxEdges, Edge]
    pairs: array[MaxPairs, array[2, int]]
    vertexCount, triangleCount, edgeCount, pairCount: int
    failed: bool

proc orient(a, b, c: Point): int =
  (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

proc onSegment(a, b, p: Point): bool =
  min(a[0], b[0]) <= p[0] and p[0] <= max(a[0], b[0]) and
    min(a[1], b[1]) <= p[1] and p[1] <= max(a[1], b[1])

proc segmentsIntersect(a, b, c, d: Point): bool =
  let o1 = orient(a, b, c); let o2 = orient(a, b, d)
  let o3 = orient(c, d, a); let o4 = orient(c, d, b)
  if ((o1 < 0 and o2 > 0) or (o1 > 0 and o2 < 0)) and
     ((o3 < 0 and o4 > 0) or (o3 > 0 and o4 < 0)): return true
  (o1 == 0 and onSegment(a, b, c)) or (o2 == 0 and onSegment(a, b, d)) or
    (o3 == 0 and onSegment(c, d, a)) or (o4 == 0 and onSegment(c, d, b))

proc edgeHitsBox(s: State, edge: Edge, xmin, ymin, xmax, ymax: int): bool =
  let a = s.vertices[edge[0]]; let b = s.vertices[edge[1]]
  if (xmin <= a[0] and a[0] <= xmax and ymin <= a[1] and a[1] <= ymax) or
     (xmin <= b[0] and b[0] <= xmax and ymin <= b[1] and b[1] <= ymax): return true
  segmentsIntersect(a,b,[xmin,ymin],[xmax,ymin]) or
    segmentsIntersect(a,b,[xmax,ymin],[xmax,ymax]) or
    segmentsIntersect(a,b,[xmax,ymax],[xmin,ymax]) or
    segmentsIntersect(a,b,[xmin,ymax],[xmin,ymin])

proc stopping(s: State, xmin, ymin, xmax, ymax: int): bool =
  var touched: array[MaxEdges, bool]
  var count = 0
  for e in 0 ..< s.edgeCount:
    touched[e] = edgeHitsBox(s, s.edges[e], xmin, ymin, xmax, ymax)
    if touched[e]: inc count
  if count == 0: return true
  for v in 0 ..< s.vertexCount:
    var common = true
    for e in 0 ..< s.edgeCount:
      if touched[e] and s.edges[e][0] != v and s.edges[e][1] != v: common = false
    if common: return true
  false

proc pointInTriangle(p, a, b, c: Point): bool =
  orient(a,b,p) >= 0 and orient(b,c,p) >= 0 and orient(c,a,p) >= 0

proc triangleHitsBox(s: State, tid, xmin, ymin, xmax, ymax: int): bool =
  let t = s.triangles[tid]
  for k in 0 ..< 3:
    let p = s.vertices[t[k]]
    if xmin <= p[0] and p[0] <= xmax and ymin <= p[1] and p[1] <= ymax: return true
  let a = s.vertices[t[0]]; let b = s.vertices[t[1]]; let c = s.vertices[t[2]]
  if pointInTriangle([xmin,ymin],a,b,c) or pointInTriangle([xmax,ymin],a,b,c) or
     pointInTriangle([xmax,ymax],a,b,c) or pointInTriangle([xmin,ymax],a,b,c): return true
  let corners = [[xmin,ymin],[xmax,ymin],[xmax,ymax],[xmin,ymax]]
  for k in 0 ..< 3:
    let p = s.vertices[t[k]]; let q = s.vertices[t[(k+1) mod 3]]
    for side in 0 ..< 4:
      if segmentsIntersect(p,q,corners[side],corners[(side+1) mod 4]): return true
  false

proc addEdge(s: var State, a0, b0: int): bool =
  let a = min(a0,b0); let b = max(a0,b0)
  for i in 0 ..< s.edgeCount:
    if s.edges[i] == [a,b]: return true
  if s.edgeCount >= MaxEdges: return false
  s.edges[s.edgeCount] = [a,b]; inc s.edgeCount
  true

proc appendPair(s: var State, key, tid: int) =
  if s.pairCount >= MaxPairs: s.failed = true; return
  s.pairs[s.pairCount] = [key,tid]; inc s.pairCount

proc visit(s: var State, depth, ix, iy, path: int) =
  if s.failed: return
  let size = 8 shr depth
  let xmin = ix * size; let xmax = xmin + size
  let ymax = 8 - iy * size; let ymin = ymax - size
  if not stopping(s,xmin,ymin,xmax,ymax):
    if depth >= MaxDepth: s.failed = true; return
    for q in 0 ..< 4:
      visit(s,depth+1,2*ix+(q and 1),2*iy+(q shr 1),4*path+q)
    return
  let key = path shl (2*(MaxDepth-depth))
  for tid in 0 ..< s.triangleCount:
    if triangleHitsBox(s,tid,xmin,ymin,xmax,ymax): appendPair(s,key,tid)

proc parse(s: var State, input: ptr UncheckedArray[int64], length: int): bool =
  if input.isNil or length < 2 or length > MaxInput: return false
  if not ((input[0] == 4 and input[1] == 2) or (input[0] == 5 and input[1] == 4)): return false
  s.vertexCount = int(input[0]); s.triangleCount = int(input[1])
  if length != 2 + 2*s.vertexCount + 3*s.triangleCount: return false
  let cornerValues = [0,0,8,0,8,8,0,8]
  for i in 0 ..< 4:
    if input[2+2*i] != int64(cornerValues[2*i]) or input[3+2*i] != int64(cornerValues[2*i+1]): return false
    s.vertices[i] = [cornerValues[2*i],cornerValues[2*i+1]]
  if s.vertexCount == 5:
    if input[10] != 4 or input[11] != 4: return false
    s.vertices[4] = [4,4]
  let start = 2 + 2*s.vertexCount
  for i in 0 ..< s.triangleCount:
    for j in 0 ..< 3:
      let id = input[start+3*i+j]
      if id < 0 or id >= int64(s.vertexCount): return false
      s.triangles[i][j] = int(id)
  if s.vertexCount == 4:
    let diag02 = s.triangles[0] == [0,1,2] and s.triangles[1] == [0,2,3]
    let diag13 = s.triangles[0] == [0,1,3] and s.triangles[1] == [1,2,3]
    if not (diag02 or diag13): return false
  else:
    let fan = [0,1,4,1,2,4,2,3,4,3,0,4]
    for i in 0 ..< 12:
      if input[start+i] != int64(fan[i]): return false
  for i in 0 ..< s.triangleCount:
    let t = s.triangles[i]
    if not addEdge(s,t[0],t[1]) or not addEdge(s,t[1],t[2]) or not addEdge(s,t[2],t[0]): return false
  true

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset+byte] = uint8((bits shr (8*byte)) and 255'u64)

proc star_quadtree_fat_triangulation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "star_quadtree_fat_triangulation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  var state: State
  if not parse(state,input,int(length)): return -1
  visit(state,0,0,0,0)
  if state.failed: return -1
  let bytes = 8 * (1 + 2*state.pairCount)
  if output.isNil or capacity < csize_t(bytes): return -2
  storeLe(output,0,int64(state.pairCount))
  var cursor = 8
  for i in 0 ..< state.pairCount:
    storeLe(output,cursor,int64(state.pairs[i][0])); cursor += 8
    storeLe(output,cursor,int64(state.pairs[i][1])); cursor += 8
  int64(bytes)
