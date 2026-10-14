## Breadth-first indexed binary-tree traversal, recording each level boundary.
proc level_order_traversal*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64, outputValues: ptr UncheckedArray[int64], outputCapacity: csize_t,
    levelOffsets: ptr UncheckedArray[csize_t], levelOffsetsCapacity: csize_t,
    queue: ptr UncheckedArray[csize_t], queueCapacity: csize_t): int64
    {.cdecl, exportc: "level_order_traversal".} =
  if nodeCount == 0:
    if rootIndex != -1: return -1
    if levelOffsets == nil or levelOffsetsCapacity < 1: return -2
    levelOffsets[0] = 0
    return 0
  if nodeCount > 4096 or nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  if outputValues == nil or outputCapacity < nodeCount or levelOffsets == nil or
      levelOffsetsCapacity < nodeCount + 1 or queue == nil or queueCapacity < nodeCount: return -2

  var head = csize_t(0)
  var tail = csize_t(1)
  var visited = csize_t(0)
  var levels = csize_t(0)
  queue[0] = csize_t(rootIndex)
  levelOffsets[0] = 0
  while head < tail:
    let levelEnd = tail
    while head < levelEnd:
      let node = queue[head]
      inc head
      outputValues[visited] = nodes[3 * node]
      inc visited
      let left = nodes[3 * node + 1]
      let right = nodes[3 * node + 2]
      if left < -1 or right < -1: return -1
      if left >= 0:
        if uint64(left) >= uint64(nodeCount) or tail >= queueCapacity: return -1
        queue[tail] = csize_t(left)
        inc tail
      if right >= 0:
        if uint64(right) >= uint64(nodeCount) or tail >= queueCapacity: return -1
        queue[tail] = csize_t(right)
        inc tail
    inc levels
    levelOffsets[levels] = visited
  if visited != nodeCount: return -1
  int64(levels)
