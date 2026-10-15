const MaxNodes = 1023
const ColumnCount = 2 * MaxNodes + 1

proc vertical_order_traversal*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64, outputValues: ptr UncheckedArray[int64], outputCapacity: csize_t,
    columnOffsets: ptr UncheckedArray[csize_t], offsetsCapacity: csize_t,
    queue: ptr UncheckedArray[csize_t], queueCapacity: csize_t): int64
    {.cdecl, exportc: "vertical_order_traversal".} =
  if nodeCount > MaxNodes.csize_t: return -1
  if nodeCount == 0:
    if rootIndex != -1: return -1
    if columnOffsets.isNil or offsetsCapacity < 1: return -2
    columnOffsets[0] = 0
    return 0
  if nodes.isNil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  if outputValues.isNil or outputCapacity < nodeCount or columnOffsets.isNil or
      offsetsCapacity < nodeCount + 1 or queue.isNil or queueCapacity < nodeCount: return -2
  let count = int(nodeCount)
  var parents: array[MaxNodes, int]
  for node in 0 ..< count:
    let value = nodes[3 * node]
    let left = nodes[3 * node + 1]
    let right = nodes[3 * node + 2]
    if value < int64(low(int32)) or value > int64(high(int32)) or left < -1 or right < -1 or
        (left >= 0 and uint64(left) >= uint64(nodeCount)) or
        (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
    if left >= 0:
      inc parents[int(left)]
      if parents[int(left)] > 1: return -1
    if right >= 0:
      inc parents[int(right)]
      if parents[int(right)] > 1: return -1
  let root = int(rootIndex)
  if parents[root] != 0: return -1
  for node in 0 ..< count:
    if node != root and parents[node] != 1: return -1
  var columns: array[MaxNodes, int64]
  var nextColumn: array[MaxNodes, int64]
  var bucketHead, bucketTail: array[ColumnCount, int64]
  var visited: array[MaxNodes, bool]
  for slot in 0 ..< ColumnCount:
    bucketHead[slot] = -1; bucketTail[slot] = -1
  var head = 0
  var tail = 1
  var reached = 0
  var minimum = 0'i64
  var maximum = 0'i64
  queue[0] = csize_t(root)
  columns[root] = 0
  visited[root] = true
  while head < tail:
    let node = int(queue[head]); inc head
    let coordinate = columns[node]
    let slot = int(coordinate + MaxNodes.int64)
    nextColumn[node] = -1
    if bucketHead[slot] < 0: bucketHead[slot] = int64(node)
    else: nextColumn[int(bucketTail[slot])] = int64(node)
    bucketTail[slot] = int64(node)
    inc reached
    let left = nodes[3 * node + 1]
    let right = nodes[3 * node + 2]
    if left >= 0:
      let child = int(left)
      if visited[child] or tail >= int(queueCapacity): return -1
      visited[child] = true; columns[child] = coordinate - 1; queue[tail] = csize_t(child); inc tail
      minimum = min(minimum, columns[child])
    if right >= 0:
      let child = int(right)
      if visited[child] or tail >= int(queueCapacity): return -1
      visited[child] = true; columns[child] = coordinate + 1; queue[tail] = csize_t(child); inc tail
      maximum = max(maximum, columns[child])
  if reached != count: return -1
  var written = 0
  var columnCount = 0
  columnOffsets[0] = 0
  var coordinate = minimum
  while coordinate <= maximum:
    let slot = int(coordinate + MaxNodes.int64)
    var node = bucketHead[slot]
    while node >= 0:
      outputValues[written] = nodes[3 * int(node)]
      inc written
      node = nextColumn[int(node)]
    inc columnCount
    columnOffsets[columnCount] = csize_t(written)
    inc coordinate
  int64(columnCount)
