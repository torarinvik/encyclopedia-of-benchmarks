const
  MaxNodes = 64
  MaxDirectedEdges = 2 * (MaxNodes - 1)
  InvalidParent = -2'i32

type
  CentroidState = object
    setParent: array[MaxNodes, int32]
    head: array[MaxNodes, int32]
    edgeTo: array[MaxDirectedEdges, int32]
    edgeNext: array[MaxDirectedEdges, int32]
    removed: array[MaxNodes, bool]
    traversalParent: array[MaxNodes, int32]
    subtreeSize: array[MaxNodes, int32]
    order: array[MaxNodes, int32]
    stack: array[MaxNodes, int32]
    taskNode: array[MaxNodes, int32]
    taskParent: array[MaxNodes, int32]
    decompositionParent: array[MaxNodes, int32]

proc findSet(parent: var array[MaxNodes, int32], start: int32): int32 =
  var node = start
  while parent[int(node)] != node:
    node = parent[int(node)]
  node

proc centroidDecomposition*(values: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                            {.cdecl, exportc: "centroid_decomposition".} =
  if values == nil or length < 1 or length > csize_t(2 * MaxNodes - 1): return -1
  if values[0] < 1 or values[0] > MaxNodes: return -1
  let nodeCount = int(values[0])
  if int(length) != 2 * nodeCount - 1: return -1

  var state: CentroidState
  for node in 0 ..< nodeCount:
    state.setParent[node] = int32(node)
    state.head[node] = -1
  var edgeCount = 0
  var position = 1
  while position < int(length):
    let leftValue = values[position]
    let rightValue = values[position + 1]
    if leftValue < 0 or leftValue >= nodeCount or rightValue < 0 or rightValue >= nodeCount or leftValue == rightValue: return -1
    let left = int32(leftValue)
    let right = int32(rightValue)
    let leftRoot = findSet(state.setParent, left)
    let rightRoot = findSet(state.setParent, right)
    if leftRoot == rightRoot: return -1
    state.setParent[int(rightRoot)] = leftRoot
    state.edgeTo[edgeCount] = right
    state.edgeNext[edgeCount] = state.head[int(left)]
    state.head[int(left)] = int32(edgeCount)
    inc edgeCount
    state.edgeTo[edgeCount] = left
    state.edgeNext[edgeCount] = state.head[int(right)]
    state.head[int(right)] = int32(edgeCount)
    inc edgeCount
    position += 2

  let requiredBytes = csize_t(nodeCount * 4)
  if outputCapacity < requiredBytes or output == nil: return -2

  for node in 0 ..< nodeCount:
    state.traversalParent[node] = InvalidParent
    state.decompositionParent[node] = InvalidParent
  var taskCount = 1
  state.taskNode[0] = 0
  state.taskParent[0] = -1
  while taskCount > 0:
    dec taskCount
    let start = int(state.taskNode[taskCount])
    let centroidParent = state.taskParent[taskCount]
    for node in 0 ..< nodeCount:
      state.traversalParent[node] = InvalidParent
    var stackCount = 1
    var orderCount = 0
    state.stack[0] = int32(start)
    state.traversalParent[start] = -1
    while stackCount > 0:
      dec stackCount
      let node = int(state.stack[stackCount])
      state.order[orderCount] = int32(node)
      inc orderCount
      state.subtreeSize[node] = 1
      var edge = state.head[node]
      while edge >= 0:
        let edgeIndex = int(edge)
        let neighbor = int(state.edgeTo[edgeIndex])
        if state.edgeTo[edgeIndex] != state.traversalParent[node] and not state.removed[neighbor] and state.traversalParent[neighbor] == InvalidParent:
          state.traversalParent[neighbor] = int32(node)
          state.stack[stackCount] = int32(neighbor)
          inc stackCount
        edge = state.edgeNext[edgeIndex]
    var index = orderCount
    while index > 0:
      dec index
      let node = int(state.order[index])
      let parent = int(state.traversalParent[node])
      if parent >= 0:
        state.subtreeSize[parent] += state.subtreeSize[node]

    var centroid = -1'i32
    var smallestLargestBranch = int32(nodeCount + 1)
    for orderIndex in 0 ..< orderCount:
      let node = int(state.order[orderIndex])
      var largestBranch = int32(orderCount) - state.subtreeSize[node]
      var edge = state.head[node]
      while edge >= 0:
        let edgeIndex = int(edge)
        let neighbor = int(state.edgeTo[edgeIndex])
        if state.traversalParent[neighbor] == int32(node):
          largestBranch = max(largestBranch, state.subtreeSize[neighbor])
        edge = state.edgeNext[edgeIndex]
      if largestBranch < smallestLargestBranch or (largestBranch == smallestLargestBranch and int32(node) < centroid):
        centroid = int32(node)
        smallestLargestBranch = largestBranch

    let center = int(centroid)
    state.decompositionParent[center] = centroidParent
    state.removed[center] = true
    var edge = state.head[center]
    while edge >= 0:
      let edgeIndex = int(edge)
      let neighbor = int(state.edgeTo[edgeIndex])
      if not state.removed[neighbor]:
        state.taskNode[taskCount] = int32(neighbor)
        state.taskParent[taskCount] = centroid
        inc taskCount
      edge = state.edgeNext[edgeIndex]

  for node in 0 ..< nodeCount:
    let bits = cast[uint32](state.decompositionParent[node])
    output[4 * node] = uint8(bits and 0xff)
    output[4 * node + 1] = uint8((bits shr 8) and 0xff)
    output[4 * node + 2] = uint8((bits shr 16) and 0xff)
    output[4 * node + 3] = uint8((bits shr 24) and 0xff)
  int64(nodeCount)
