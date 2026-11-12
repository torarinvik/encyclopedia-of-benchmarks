const MaxVertices = 16
const MaxEvents = 32
const MaxInputValues = 2 + 4 * MaxEvents + 1
const TreeNodes = 4 * MaxEvents + 8

proc findRoot(parent: openArray[int], vertexInput: int): int =
  var vertex = vertexInput
  while parent[vertex] != vertex:
    vertex = parent[vertex]
  vertex

proc addInterval(node, left, right, queryLeft, queryRight, edgeId: int,
    bucketCount: var array[TreeNodes, int],
    buckets: var array[TreeNodes, array[MaxEvents, int]]) =
  if queryLeft <= left and right <= queryRight:
    buckets[node][bucketCount[node]] = edgeId
    inc bucketCount[node]
    return
  let middle = left + (right - left) div 2
  if queryLeft < middle:
    addInterval(node * 2, left, middle, queryLeft, queryRight, edgeId, bucketCount, buckets)
  if queryRight > middle:
    addInterval(node * 2 + 1, middle, right, queryLeft, queryRight, edgeId, bucketCount, buckets)

proc unite(left, right: int, parent, setSize: var array[MaxVertices, int],
    historyChild, historyRoot, historySize: var array[MaxVertices, int],
    historyCount: var int) =
  var rootLeft = findRoot(parent, left)
  var rootRight = findRoot(parent, right)
  if rootLeft == rootRight: return
  if setSize[rootLeft] > setSize[rootRight]: swap(rootLeft, rootRight)
  historyChild[historyCount] = rootLeft
  historyRoot[historyCount] = rootRight
  historySize[historyCount] = setSize[rootRight]
  inc historyCount
  parent[rootLeft] = rootRight
  setSize[rootRight] += setSize[rootLeft]

proc rollbackTo(checkpoint: int, parent, setSize: var array[MaxVertices, int],
    historyChild, historyRoot, historySize: array[MaxVertices, int],
    historyCount: var int) =
  while historyCount > checkpoint:
    dec historyCount
    let child = historyChild[historyCount]
    let root = historyRoot[historyCount]
    parent[child] = child
    setSize[root] = historySize[historyCount]

proc solveTimeTree(node, left, right: int,
    operation, first, second, edgeLeft, edgeRight: array[MaxEvents, int64],
    bucketCount: var array[TreeNodes, int],
    buckets: var array[TreeNodes, array[MaxEvents, int]],
    parent, setSize: var array[MaxVertices, int],
    historyChild, historyRoot, historySize: var array[MaxVertices, int],
    historyCount: var int, answer: var array[MaxEvents, int64]) =
  let checkpoint = historyCount
  for entry in 0 ..< bucketCount[node]:
    let edgeId = buckets[node][entry]
    unite(int(edgeLeft[edgeId]), int(edgeRight[edgeId]), parent, setSize,
      historyChild, historyRoot, historySize, historyCount)
  if right - left == 1:
    if operation[left] == 2:
      answer[left] = int64(ord(findRoot(parent, int(first[left])) == findRoot(parent, int(second[left]))))
  else:
    let middle = left + (right - left) div 2
    solveTimeTree(node * 2, left, middle, operation, first, second,
      edgeLeft, edgeRight, bucketCount, buckets, parent, setSize,
      historyChild, historyRoot, historySize, historyCount, answer)
    solveTimeTree(node * 2 + 1, middle, right, operation, first, second,
      edgeLeft, edgeRight, bucketCount, buckets, parent, setSize,
      historyChild, historyRoot, historySize, historyCount, answer)
  rollbackTo(checkpoint, parent, setSize, historyChild, historyRoot, historySize, historyCount)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc offline_dynamic_connectivity*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "offline_dynamic_connectivity".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  if input[0] < 1 or input[0] > MaxVertices or input[1] < 0 or input[1] > MaxEvents: return -1
  let vertexCount = int(input[0])
  let eventCount = int(input[1])
  if int(length) != 2 + 4 * eventCount: return -1

  var operation, first, second, edgeLeft, edgeRight: array[MaxEvents, int64]
  var startTime: array[MaxEvents, int]
  var usedId, active: array[MaxEvents, bool]
  var queryCount = 0
  for time in 0 ..< eventCount:
    let offset = 2 + 4 * time
    operation[time] = input[offset]
    first[time] = input[offset + 1]
    second[time] = input[offset + 2]
    let third = input[offset + 3]
    if operation[time] == 0:
      let edgeId = first[time]
      if edgeId < 0 or edgeId >= MaxEvents or second[time] < 0 or
          second[time] >= vertexCount or third < 0 or third >= vertexCount or
          usedId[int(edgeId)]: return -1
      usedId[int(edgeId)] = true
      active[int(edgeId)] = true
      startTime[int(edgeId)] = time
      edgeLeft[int(edgeId)] = second[time]
      edgeRight[int(edgeId)] = third
    elif operation[time] == 1:
      let edgeId = first[time]
      if edgeId < 0 or edgeId >= MaxEvents or not active[int(edgeId)] or
          second[time] != 0 or third != 0: return -1
      active[int(edgeId)] = false
    elif operation[time] == 2:
      if first[time] < 0 or first[time] >= vertexCount or second[time] < 0 or
          second[time] >= vertexCount or third != 0: return -1
      inc queryCount
    else:
      return -1

  let required = 8 * queryCount
  if output.isNil or int(capacity) < required: return -2
  var bucketCount: array[TreeNodes, int]
  var buckets: array[TreeNodes, array[MaxEvents, int]]
  for edgeId in 0 ..< MaxEvents:
    if not usedId[edgeId]: continue
    var endTime = eventCount
    if not active[edgeId]:
      for time in (startTime[edgeId] + 1) ..< eventCount:
        if operation[time] == 1 and first[time] == edgeId:
          endTime = time
          break
    if startTime[edgeId] < endTime and eventCount != 0:
      addInterval(1, 0, eventCount, startTime[edgeId], endTime, edgeId, bucketCount, buckets)

  var parent, setSize: array[MaxVertices, int]
  for vertex in 0 ..< vertexCount:
    parent[vertex] = vertex
    setSize[vertex] = 1
  var historyChild, historyRoot, historySize: array[MaxVertices, int]
  var historyCount = 0
  var answer: array[MaxEvents, int64]
  if eventCount != 0:
    solveTimeTree(1, 0, eventCount, operation, first, second, edgeLeft, edgeRight,
      bucketCount, buckets, parent, setSize, historyChild, historyRoot, historySize,
      historyCount, answer)

  var written = 0
  for time in 0 ..< eventCount:
    if operation[time] == 2:
      storeI64Le(output, written, answer[time])
      written += 8
  int64(written)
