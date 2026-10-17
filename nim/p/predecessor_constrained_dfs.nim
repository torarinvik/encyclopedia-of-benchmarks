const MaxNodes = 16
const MaxInputValues = 2 + MaxNodes * MaxNodes
const MaxEvents = MaxNodes + MaxNodes * (MaxNodes - 1) div 2
const MatrixSize = MaxNodes * MaxNodes

type
  Matrix = array[MatrixSize, bool]
  EventValues = array[MaxEvents * 3, int32]

proc visitNode(node, count: int, adjacent, predecessors: var Matrix,
    visited: var array[MaxNodes, bool], events: var EventValues,
    eventCount: var int, nextOrder: var int32): bool =
  if eventCount >= MaxEvents: return false
  visited[node] = true
  let index = 3 * eventCount
  events[index] = 1; events[index + 1] = int32(node); events[index + 2] = nextOrder
  inc eventCount; inc nextOrder
  for child in 0 ..< count:
    if not adjacent[node * MaxNodes + child] or visited[child]: continue
    var allVisited = true
    for parent in 0 ..< count:
      if predecessors[child * MaxNodes + parent] and not visited[parent]:
        allVisited = false
        break
    if allVisited:
      if not visitNode(child, count, adjacent, predecessors, visited, events, eventCount, nextOrder): return false
    else:
      if eventCount >= MaxEvents: return false
      let eventIndex = 3 * eventCount
      events[eventIndex] = 0; events[eventIndex + 1] = int32(child); events[eventIndex + 2] = -1
      inc eventCount
  true

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff)

proc predecessor_constrained_dfs*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "predecessor_constrained_dfs".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let rawCount = input[0]
  let rawStart = input[1]
  if rawCount < 1 or rawCount > MaxNodes or rawStart < 0 or rawStart >= rawCount: return -1
  let count = int(rawCount)
  if int(length) != 2 + count * count: return -1
  var adjacent: Matrix
  var predecessors: Matrix
  var indegree: array[MaxNodes, int]
  for fromNode in 0 ..< count:
    for toNode in 0 ..< count:
      let bit = input[2 + fromNode * count + toNode]
      if (bit != 0 and bit != 1) or (fromNode == toNode and bit != 0): return -1
      if bit == 1:
        adjacent[fromNode * MaxNodes + toNode] = true
        predecessors[toNode * MaxNodes + fromNode] = true
        inc indegree[toNode]
  var queue: array[MaxNodes, int]
  var head = 0
  var tail = 0
  for node in 0 ..< count:
    if indegree[node] == 0: queue[tail] = node; inc tail
  while head < tail:
    let node = queue[head]
    inc head
    for child in 0 ..< count:
      if adjacent[node * MaxNodes + child]:
        dec indegree[child]
        if indegree[child] == 0: queue[tail] = child; inc tail
  if tail != count: return -1
  var visited: array[MaxNodes, bool]
  var events: EventValues
  var eventCount = 0
  var nextOrder: int32 = 0
  if not visitNode(int(rawStart), count, adjacent, predecessors, visited, events, eventCount, nextOrder): return -1
  let byteCount = 12 * eventCount
  if output.isNil or outputCapacity < csize_t(byteCount): return -2
  for event in 0 ..< eventCount:
    let index = 3 * event
    writeI32Le(output, 12 * event, events[index])
    writeI32Le(output, 12 * event + 4, events[index + 1])
    writeI32Le(output, 12 * event + 8, events[index + 2])
  int64(byteCount)
