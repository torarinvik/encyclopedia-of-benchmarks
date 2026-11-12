const
  maxVertices = 64
  maxEdges = 128
  maxInputLength = 2 + 2 * maxEdges + 1

type
  BridgeState = object
    dsu2ecc: array[maxVertices, int]
    dsuCc: array[maxVertices, int]
    dsuCcSize: array[maxVertices, int]
    parent: array[maxVertices, int]
    lastVisit: array[maxVertices, int]
    iteration: int
    bridges: int
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc find2ecc(state: var BridgeState, vertex: int): int =
  if vertex == -1: return -1
  if state.dsu2ecc[vertex] == vertex: return vertex
  state.dsu2ecc[vertex] = find2ecc(state, state.dsu2ecc[vertex])
  state.dsu2ecc[vertex]

proc findCc(state: var BridgeState, vertexInput: int): int =
  let vertex = find2ecc(state, vertexInput)
  if state.dsuCc[vertex] == vertex: return vertex
  state.dsuCc[vertex] = findCc(state, state.dsuCc[vertex])
  state.dsuCc[vertex]

proc makeRoot(state: var BridgeState, vertexInput: int) =
  let root = find2ecc(state, vertexInput)
  var vertex = root
  var child = -1
  while vertex != -1:
    let next = find2ecc(state, state.parent[vertex])
    state.parent[vertex] = child
    state.dsuCc[vertex] = root
    child = vertex
    vertex = next
  state.dsuCcSize[root] = state.dsuCcSize[child]

proc mergePath(state: var BridgeState, leftInput, rightInput: int) =
  state.iteration += 1
  var pathLeft: array[maxVertices, int]
  var pathRight: array[maxVertices, int]
  var leftLength = 0
  var rightLength = 0
  var left = leftInput
  var right = rightInput
  var lca = -1
  while lca == -1:
    if left != -1:
      left = find2ecc(state, left)
      pathLeft[leftLength] = left
      inc leftLength
      if state.lastVisit[left] == state.iteration:
        lca = left
        break
      state.lastVisit[left] = state.iteration
      left = state.parent[left]
    if right != -1:
      right = find2ecc(state, right)
      pathRight[rightLength] = right
      inc rightLength
      if state.lastVisit[right] == state.iteration:
        lca = right
        break
      state.lastVisit[right] = state.iteration
      right = state.parent[right]
  for index in 0 ..< leftLength:
    let vertex = pathLeft[index]
    state.dsu2ecc[vertex] = lca
    if vertex == lca: break
    dec state.bridges
  for index in 0 ..< rightLength:
    let vertex = pathRight[index]
    state.dsu2ecc[vertex] = lca
    if vertex == lca: break
    dec state.bridges

proc addEdge(state: var BridgeState, leftInput, rightInput: int) =
  var left = find2ecc(state, leftInput)
  var right = find2ecc(state, rightInput)
  if left == right: return
  var leftCc = findCc(state, left)
  var rightCc = findCc(state, right)
  if leftCc != rightCc:
    inc state.bridges
    if state.dsuCcSize[leftCc] > state.dsuCcSize[rightCc]:
      swap(left, right)
      swap(leftCc, rightCc)
    makeRoot(state, left)
    state.parent[left] = right
    state.dsuCc[left] = right
    state.dsuCcSize[rightCc] += state.dsuCcSize[left]
  else:
    mergePath(state, left, right)

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc online_bridge_finding*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "online_bridge_finding".} =
  if values == nil or length < 2 or length > maxInputLength: return -1
  let rawVertices = values[0]
  let rawEdges = values[1]
  if rawVertices < 1 or rawVertices > maxVertices or rawEdges < 0 or rawEdges > maxEdges:
    return -1
  let vertexCount = int(rawVertices)
  let edgeCount = int(rawEdges)
  if length != 2 + 2 * edgeCount: return -1
  for edge in 0 ..< edgeCount:
    let left = values[2 + 2 * edge]
    let right = values[3 + 2 * edge]
    if left < 0 or right < 0 or left >= rawVertices or right >= rawVertices: return -1
  let outputBytes = edgeCount * 8
  if outputBytes > 0 and (output == nil or outputCapacity < outputBytes): return -2

  var state = BridgeState()
  for vertex in 0 ..< vertexCount:
    state.dsu2ecc[vertex] = vertex
    state.dsuCc[vertex] = vertex
    state.dsuCcSize[vertex] = 1
    state.parent[vertex] = -1
  for edge in 0 ..< edgeCount:
    addEdge(state, int(values[2 + 2 * edge]), int(values[3 + 2 * edge]))
    storeI64Le(output, edge * 8, int64(state.bridges))
  int64(outputBytes)
