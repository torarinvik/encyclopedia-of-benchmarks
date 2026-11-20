const
  MaxVertices = 8
  MaxEdges = 24
  MaxInputLength = 51
  CountScale = 1_000_000_000_000'i64

type
  Graph = array[MaxVertices, array[MaxVertices, bool]]
  SccState = object
    graph: Graph
    n, lowerBound: int
    nextIndex, componentCount, stackLength: int
    index, lowLink, componentId: array[MaxVertices, int]
    onStack: array[MaxVertices, bool]
    stack: array[MaxVertices, int]
    componentSize, componentMinimum: array[MaxVertices, int]
  CircuitState = object
    graph: Graph
    n, start, selectedComponent, depth: int
    componentId: array[MaxVertices, int]
    blocked: array[MaxVertices, bool]
    dependencies: array[MaxVertices * MaxVertices, bool]
    path: array[MaxVertices, int]
    count, codeSum: int64

proc strongConnect(vertex: int, state: var SccState) =
  state.index[vertex] = state.nextIndex
  state.lowLink[vertex] = state.nextIndex
  inc state.nextIndex
  state.stack[state.stackLength] = vertex
  inc state.stackLength
  state.onStack[vertex] = true

  for neighbor in state.lowerBound ..< state.n:
    if not state.graph[vertex][neighbor]: continue
    if state.index[neighbor] < 0:
      strongConnect(neighbor, state)
      state.lowLink[vertex] = min(state.lowLink[vertex], state.lowLink[neighbor])
    elif state.onStack[neighbor]:
      state.lowLink[vertex] = min(state.lowLink[vertex], state.index[neighbor])

  if state.lowLink[vertex] == state.index[vertex]:
    let component = state.componentCount
    var size = 0
    var minimum = state.n
    while true:
      dec state.stackLength
      let member = state.stack[state.stackLength]
      state.onStack[member] = false
      state.componentId[member] = component
      inc size
      minimum = min(minimum, member)
      if member == vertex: break
    state.componentSize[component] = size
    state.componentMinimum[component] = minimum
    inc state.componentCount

proc findSelectedComponent(n, lowerBound: int, graph: Graph,
    componentId: var array[MaxVertices, int]): tuple[start, component: int] =
  var state: SccState
  state.graph = graph
  state.n = n
  state.lowerBound = lowerBound
  for vertex in 0 ..< MaxVertices:
    state.index[vertex] = -1
    state.lowLink[vertex] = -1
    state.componentId[vertex] = -1
  for vertex in lowerBound ..< n:
    if state.index[vertex] < 0: strongConnect(vertex, state)
  for vertex in 0 ..< n: componentId[vertex] = state.componentId[vertex]

  result.start = n
  result.component = -1
  for component in 0 ..< state.componentCount:
    if state.componentSize[component] > 1 and state.componentMinimum[component] < result.start:
      result.start = state.componentMinimum[component]
      result.component = component

proc unblock(vertex: int, state: var CircuitState) =
  if not state.blocked[vertex]: return
  state.blocked[vertex] = false
  for dependent in 0 ..< state.n:
    let slot = vertex * MaxVertices + dependent
    if state.dependencies[slot]:
      state.dependencies[slot] = false
      if state.blocked[dependent]: unblock(dependent, state)

proc recordCycle(state: var CircuitState) =
  var code = 0'i64
  var place = 1'i64
  for index in 0 ..< state.depth:
    code += int64(state.path[index] + 1) * place
    place *= 9
  inc state.count
  state.codeSum += code

proc circuit(vertex: int, state: var CircuitState): bool =
  state.path[state.depth] = vertex
  inc state.depth
  state.blocked[vertex] = true
  var found = false
  for neighbor in 0 ..< state.n:
    if not state.graph[vertex][neighbor] or state.componentId[neighbor] != state.selectedComponent: continue
    if neighbor == state.start:
      recordCycle(state)
      found = true
    elif not state.blocked[neighbor] and circuit(neighbor, state):
      found = true
  if found:
    unblock(vertex, state)
  else:
    for neighbor in 0 ..< state.n:
      if state.graph[vertex][neighbor] and state.componentId[neighbor] == state.selectedComponent:
        state.dependencies[neighbor * MaxVertices + vertex] = true
  dec state.depth
  found

proc johnson_elementary_circuit_enumeration*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "johnson_elementary_circuit_enumeration".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 1 or nValue > int64(MaxVertices) or mValue < 0 or mValue > int64(MaxEdges): return -1
  let n = int(nValue)
  let m = int(mValue)
  if length != csize_t(2 + 2 * m): return -1

  var graph: Graph
  for edgeIndex in 0 ..< m:
    let fromValue = input[2 + 2 * edgeIndex]
    let toValue = input[3 + 2 * edgeIndex]
    if fromValue < 0 or fromValue >= nValue or toValue < 0 or toValue >= nValue or fromValue == toValue:
      return -1
    let fromVertex = int(fromValue)
    let toVertex = int(toValue)
    if graph[fromVertex][toVertex]: return -1
    graph[fromVertex][toVertex] = true

  var lowerBound = 0
  var totalCount = 0'i64
  var totalCodeSum = 0'i64
  while lowerBound < n:
    var componentId: array[MaxVertices, int]
    let selected = findSelectedComponent(n, lowerBound, graph, componentId)
    if selected.component < 0: break
    var state: CircuitState
    state.graph = graph
    state.n = n
    state.start = selected.start
    state.selectedComponent = selected.component
    state.componentId = componentId
    discard circuit(state.start, state)
    totalCount += state.count
    totalCodeSum += state.codeSum
    lowerBound = selected.start + 1
  totalCount * CountScale + totalCodeSum
