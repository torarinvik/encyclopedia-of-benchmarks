const
  MaxVertices = 8
  MaxEdges = 16
  MaxInputLength = 4 + 3 * MaxEdges + 1

  FreeTree = 0
  SourceTree = 1
  SinkTree = 2

type FlowState = object
  n: int
  source: int
  sink: int
  residual: array[MaxVertices, array[MaxVertices, int64]]
  tree: array[MaxVertices, int]
  parent: array[MaxVertices, int]
  activeQueue: array[MaxVertices, int]
  activeHead: int
  activeTail: int
  activeCount: int
  isActive: array[MaxVertices, bool]
  orphanQueue: array[MaxVertices, int]
  orphanHead: int
  orphanTail: int
  orphanCount: int
  isOrphan: array[MaxVertices, bool]
  totalFlow: int64

proc treeCapacity(state: var FlowState, kind, parentVertex, childVertex: int): int64 =
  if kind == SourceTree:
    state.residual[parentVertex][childVertex]
  else:
    state.residual[childVertex][parentVertex]

proc enqueueActive(state: var FlowState, vertex: int) =
  if state.isActive[vertex]: return
  if state.activeTail >= MaxVertices:
    for offset in 0 ..< state.activeCount:
      state.activeQueue[offset] = state.activeQueue[state.activeHead + offset]
    state.activeHead = 0
    state.activeTail = state.activeCount
  state.activeQueue[state.activeTail] = vertex
  inc state.activeTail
  inc state.activeCount
  state.isActive[vertex] = true

proc dequeueActive(state: var FlowState): int =
  result = state.activeQueue[state.activeHead]
  inc state.activeHead
  dec state.activeCount
  state.isActive[result] = false
  if state.activeCount == 0:
    state.activeHead = 0
    state.activeTail = 0

proc removeActive(state: var FlowState, vertex: int) =
  if not state.isActive[vertex]: return
  var index = state.activeHead
  while index < state.activeTail:
    if state.activeQueue[index] == vertex:
      var shift = index
      while shift + 1 < state.activeTail:
        state.activeQueue[shift] = state.activeQueue[shift + 1]
        inc shift
      dec state.activeTail
      dec state.activeCount
      state.isActive[vertex] = false
      if state.activeCount == 0:
        state.activeHead = 0
        state.activeTail = 0
      return
    inc index

proc enqueueOrphan(state: var FlowState, vertex: int) =
  if state.isOrphan[vertex]: return
  if state.orphanTail >= MaxVertices:
    for offset in 0 ..< state.orphanCount:
      state.orphanQueue[offset] = state.orphanQueue[state.orphanHead + offset]
    state.orphanHead = 0
    state.orphanTail = state.orphanCount
  state.orphanQueue[state.orphanTail] = vertex
  inc state.orphanTail
  inc state.orphanCount
  state.isOrphan[vertex] = true

proc dequeueOrphan(state: var FlowState): int =
  result = state.orphanQueue[state.orphanHead]
  inc state.orphanHead
  dec state.orphanCount
  state.isOrphan[result] = false
  if state.orphanCount == 0:
    state.orphanHead = 0
    state.orphanTail = 0

proc hasTerminalOrigin(state: var FlowState, vertex, kind, blocked: int): bool =
  let root = if kind == SourceTree: state.source else: state.sink
  var seen: array[MaxVertices, bool]
  var current = vertex
  while true:
    if current == blocked or current < 0 or current >= state.n or seen[current] or state.tree[current] != kind:
      return false
    if current == root: return true
    seen[current] = true
    let nextVertex = state.parent[current]
    if nextVertex < 0 or nextVertex >= state.n: return false
    if treeCapacity(state, kind, nextVertex, current) <= 0: return false
    current = nextVertex

proc solve(n, source, sink: int, input: ptr UncheckedArray[int64], edgeCount: int): int64 =
  var state = FlowState(n: n, source: source, sink: sink, totalFlow: 0)
  for vertex in 0 ..< n: state.parent[vertex] = -1
  for edgeIndex in 0 ..< edgeCount:
    let fromVertex = int(input[4 + 3 * edgeIndex])
    let toVertex = int(input[5 + 3 * edgeIndex])
    let capacity = input[6 + 3 * edgeIndex]
    state.residual[fromVertex][toVertex] += capacity

  state.tree[source] = SourceTree
  state.tree[sink] = SinkTree
  state.enqueueActive(source)
  state.enqueueActive(sink)

  while state.activeCount > 0:
    var bridgeSource = -1
    var bridgeSink = -1
    var foundBridge = false
    while state.activeCount > 0 and not foundBridge:
      let vertex = state.dequeueActive()
      let kind = state.tree[vertex]
      for neighbor in 0 ..< n:
        if treeCapacity(state, kind, vertex, neighbor) <= 0: continue
        if state.tree[neighbor] == FreeTree:
          state.tree[neighbor] = kind
          state.parent[neighbor] = vertex
          state.enqueueActive(neighbor)
        elif state.tree[neighbor] != kind:
          if kind == SourceTree:
            bridgeSource = vertex
            bridgeSink = neighbor
          else:
            bridgeSource = neighbor
            bridgeSink = vertex
          state.enqueueActive(vertex)
          foundBridge = true
          break
    if not foundBridge: break

    var pathFrom: array[MaxVertices, int]
    var pathTo: array[MaxVertices, int]
    var pathLength = 0
    var reversedSource: array[MaxVertices, int]
    var sourceLength = 0
    var current = bridgeSource
    while current != source:
      if current < 0 or current >= n or sourceLength >= MaxVertices: return -1
      reversedSource[sourceLength] = current
      inc sourceLength
      current = state.parent[current]
    var sourceIndex = sourceLength
    while sourceIndex > 0:
      dec sourceIndex
      let child = reversedSource[sourceIndex]
      pathFrom[pathLength] = state.parent[child]
      pathTo[pathLength] = child
      inc pathLength
    pathFrom[pathLength] = bridgeSource
    pathTo[pathLength] = bridgeSink
    inc pathLength
    current = bridgeSink
    while current != sink:
      if current < 0 or current >= n or pathLength >= MaxVertices: return -1
      let nextVertex = state.parent[current]
      if nextVertex < 0 or nextVertex >= n: return -1
      pathFrom[pathLength] = current
      pathTo[pathLength] = nextVertex
      inc pathLength
      current = nextVertex
    if pathLength == 0: return -1

    var bottleneck = state.residual[pathFrom[0]][pathTo[0]]
    for pathIndex in 1 ..< pathLength:
      bottleneck = min(bottleneck, state.residual[pathFrom[pathIndex]][pathTo[pathIndex]])
    if bottleneck <= 0: return -1
    for pathIndex in 0 ..< pathLength:
      let fromVertex = pathFrom[pathIndex]
      let toVertex = pathTo[pathIndex]
      state.residual[fromVertex][toVertex] -= bottleneck
      state.residual[toVertex][fromVertex] += bottleneck
    state.totalFlow += bottleneck

    for pathIndex in 0 ..< pathLength:
      let fromVertex = pathFrom[pathIndex]
      let toVertex = pathTo[pathIndex]
      if state.residual[fromVertex][toVertex] != 0: continue
      if state.tree[fromVertex] == SourceTree and state.tree[toVertex] == SourceTree and
          state.parent[toVertex] == fromVertex:
        state.parent[toVertex] = -1
        state.enqueueOrphan(toVertex)
      elif state.tree[fromVertex] == SinkTree and state.tree[toVertex] == SinkTree and
          state.parent[fromVertex] == toVertex:
        state.parent[fromVertex] = -1
        state.enqueueOrphan(fromVertex)

    while state.orphanCount > 0:
      let orphan = state.dequeueOrphan()
      let kind = state.tree[orphan]
      if kind == FreeTree: continue
      var replacement = -1
      for candidate in 0 ..< n:
        if candidate == orphan or state.tree[candidate] != kind: continue
        if treeCapacity(state, kind, candidate, orphan) <= 0: continue
        if state.hasTerminalOrigin(candidate, kind, orphan):
          replacement = candidate
          break
      if replacement >= 0:
        state.parent[orphan] = replacement
        continue

      for neighbor in 0 ..< n:
        if state.tree[neighbor] != kind: continue
        if treeCapacity(state, kind, neighbor, orphan) > 0:
          state.enqueueActive(neighbor)
        if state.parent[neighbor] == orphan:
          state.parent[neighbor] = -1
          state.enqueueOrphan(neighbor)
      state.tree[orphan] = FreeTree
      state.parent[orphan] = -1
      state.removeActive(orphan)

  state.totalFlow

proc boykov_kolmogorov_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "boykov_kolmogorov_maxflow".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let rawN = input[0]
  let rawM = input[1]
  let rawSource = input[2]
  let rawSink = input[3]
  if rawN < 2 or rawN > MaxVertices or rawM < 0 or rawM > MaxEdges: return -1
  let n = int(rawN)
  let edgeCount = int(rawM)
  if length != csize_t(4 + 3 * edgeCount) or rawSource < 0 or rawSource >= rawN or
      rawSink < 0 or rawSink >= rawN or rawSource == rawSink: return -1
  for edgeIndex in 0 ..< edgeCount:
    let fromVertex = input[4 + 3 * edgeIndex]
    let toVertex = input[5 + 3 * edgeIndex]
    let capacity = input[6 + 3 * edgeIndex]
    if fromVertex < 0 or fromVertex >= rawN or toVertex < 0 or toVertex >= rawN or
        fromVertex == toVertex or capacity < 0 or capacity > 15: return -1
  solve(n, int(rawSource), int(rawSink), input, edgeCount)
