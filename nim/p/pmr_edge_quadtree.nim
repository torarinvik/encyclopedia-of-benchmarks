const
  MaxSegments = 8
  MaxDepth = 8
  MaxNodes = 2048
  MaxInput = 35

type
  Node = object
    parent, quadrant, depth: int
    xmin, ymin, xmax, ymax: int64
    child: array[4, int]
    ids: array[MaxSegments, int]
    idCount: int
  State = object
    nodes: array[MaxNodes, Node]
    segments: array[MaxSegments, array[4, int64]]
    used: int

proc orient(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
proc between(a, b, p: int64): bool = (a <= p and p <= b) or (b <= p and p <= a)
proc onSegment(ax, ay, bx, by, px, py: int64): bool = between(ax,bx,px) and between(ay,by,py)
proc segIntersects(ax, ay, bx, by, cx, cy, dx, dy: int64): bool =
  let o1 = orient(ax,ay,bx,by,cx,cy)
  let o2 = orient(ax,ay,bx,by,dx,dy)
  let o3 = orient(cx,cy,dx,dy,ax,ay)
  let o4 = orient(cx,cy,dx,dy,bx,by)
  if ((o1 < 0 and o2 > 0) or (o1 > 0 and o2 < 0)) and
     ((o3 < 0 and o4 > 0) or (o3 > 0 and o4 < 0)): return true
  (o1 == 0 and onSegment(ax,ay,bx,by,cx,cy)) or
  (o2 == 0 and onSegment(ax,ay,bx,by,dx,dy)) or
  (o3 == 0 and onSegment(cx,cy,dx,dy,ax,ay)) or
  (o4 == 0 and onSegment(cx,cy,dx,dy,bx,by))

proc intersectsBox(state: State, sid: int, bounds: array[4, int64]): bool =
  let s = state.segments[sid]
  let x0 = 2 * s[0]; let y0 = 2 * s[1]; let x1 = 2 * s[2]; let y1 = 2 * s[3]
  let lx = bounds[0]; let ly = bounds[1]; let hx = bounds[2]; let hy = bounds[3]
  if (lx <= x0 and x0 <= hx and ly <= y0 and y0 <= hy) or
     (lx <= x1 and x1 <= hx and ly <= y1 and y1 <= hy): return true
  segIntersects(x0,y0,x1,y1,lx,ly,hx,ly) or segIntersects(x0,y0,x1,y1,hx,ly,hx,hy) or
  segIntersects(x0,y0,x1,y1,hx,hy,lx,hy) or segIntersects(x0,y0,x1,y1,lx,hy,lx,ly)

proc initNode(state: var State, id, parent, quadrant, depth: int, bounds: array[4, int64]) =
  state.nodes[id].parent = parent
  state.nodes[id].quadrant = quadrant
  state.nodes[id].depth = depth
  state.nodes[id].xmin = bounds[0]; state.nodes[id].ymin = bounds[1]
  state.nodes[id].xmax = bounds[2]; state.nodes[id].ymax = bounds[3]
  state.nodes[id].idCount = 0
  for q in 0 ..< 4: state.nodes[id].child[q] = -1

proc insert(state: var State, nodeId, sid, threshold: int): bool =
  if state.nodes[nodeId].child[0] >= 0:
    for q in 0 ..< 4:
      let child = state.nodes[nodeId].child[q]
      let b = [state.nodes[child].xmin, state.nodes[child].ymin, state.nodes[child].xmax, state.nodes[child].ymax]
      if intersectsBox(state, sid, b) and not insert(state, child, sid, threshold): return false
    return true
  if state.nodes[nodeId].idCount >= MaxSegments: return false
  let slot = state.nodes[nodeId].idCount
  state.nodes[nodeId].ids[slot] = sid
  inc state.nodes[nodeId].idCount
  if state.nodes[nodeId].idCount <= threshold: return true
  if state.nodes[nodeId].depth >= MaxDepth or state.used + 4 > MaxNodes: return false

  let oldIds = state.nodes[nodeId].ids
  let oldCount = state.nodes[nodeId].idCount
  let xmin = state.nodes[nodeId].xmin; let ymin = state.nodes[nodeId].ymin
  let xmax = state.nodes[nodeId].xmax; let ymax = state.nodes[nodeId].ymax
  let mx = xmin + (xmax-xmin) div 2; let my = ymin + (ymax-ymin) div 2
  let base = state.used; let depth = state.nodes[nodeId].depth + 1
  for q in 0 ..< 4:
    let x0 = if q mod 2 == 0: xmin else: mx
    let x1 = if q mod 2 == 0: mx else: xmax
    let y0 = if q < 2: my else: ymin
    let y1 = if q < 2: ymax else: my
    initNode(state, base+q, nodeId, q, depth, [x0,y0,x1,y1])
  state.used += 4
  state.nodes[nodeId].idCount = 0
  for q in 0 ..< 4: state.nodes[nodeId].child[q] = base+q
  for i in 0 ..< oldCount:
    for q in 0 ..< 4:
      let child = base+q
      let b = [state.nodes[child].xmin, state.nodes[child].ymin, state.nodes[child].xmax, state.nodes[child].ymax]
      if intersectsBox(state, oldIds[i], b) and not insert(state, child, oldIds[i], threshold): return false
  true

proc preorder(state: State, id: int, order: var array[MaxNodes, int], count: var int) =
  order[count] = id
  inc count
  if state.nodes[id].child[0] >= 0:
    for q in 0 ..< 4: preorder(state, state.nodes[id].child[q], order, count)

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset+byte] = uint8((bits shr (8*byte)) and 255'u64)

proc pmr_edge_quadtree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "pmr_edge_quadtree".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxSegments.int64 or input[1] < 1 or input[1] > MaxSegments.int64: return -1
  let count = int(input[0]); let threshold = int(input[1])
  if length != csize_t(2 + 4*count): return -1
  var state: State
  state.used = 1
  for sid in 0 ..< count:
    for k in 0 ..< 4:
      let value = input[2+4*sid+k]
      if value < 0 or value > 255: return -1
      state.segments[sid][k] = value
    if state.segments[sid][0] == state.segments[sid][2] and state.segments[sid][1] == state.segments[sid][3]: return -1
  initNode(state,0,-1,-1,0,[-1'i64,-1,511,511])
  for sid in 0 ..< count:
    if not insert(state,0,sid,threshold): return -1
  var order, remap: array[MaxNodes, int]
  var nodeCount = 0
  preorder(state,0,order,nodeCount)
  var bytes = 16
  for i in 0 ..< nodeCount: bytes += 32 + 8*state.nodes[order[i]].idCount
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< nodeCount: remap[order[i]] = i
  storeLe(output,0,int64(nodeCount)); storeLe(output,8,int64(count))
  var cursor = 16
  for i in 0 ..< nodeCount:
    let node = state.nodes[order[i]]
    storeLe(output,cursor,int64(if node.parent < 0: -1 else: remap[node.parent])); cursor += 8
    storeLe(output,cursor,int64(node.quadrant)); cursor += 8
    storeLe(output,cursor,int64(node.depth)); cursor += 8
    storeLe(output,cursor,int64(node.idCount)); cursor += 8
    for j in 0 ..< node.idCount: storeLe(output,cursor,int64(node.ids[j])); cursor += 8
  int64(bytes)
