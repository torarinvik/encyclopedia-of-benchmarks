## Eagerly materialize a BST's in-order sequence, then consume it through an iterator.
proc bst_iterator*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "bst_iterator".} =
  const maxNodeCount = 1023
  if nodeCount > maxNodeCount: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  var iteratorValues: array[maxNodeCount, int64]
  var stack: array[maxNodeCount, int]
  var top = 0
  var valueCount = 0
  var current = rootIndex
  while current != -1 or top != 0:
    while current != -1:
      if current < 0 or uint64(current) >= uint64(nodeCount) or top >= int(nodeCount): return -1
      let index = int(current)
      let left = nodes[3 * index + 1]
      let right = nodes[3 * index + 2]
      if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
          right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
      stack[top] = index
      inc top
      current = left
    dec top
    let index = stack[top]
    if valueCount >= int(nodeCount): return -1
    let value = nodes[3 * index]
    if value < -100000 or value > 100000 or
        (valueCount != 0 and iteratorValues[valueCount - 1] >= value): return -1
    iteratorValues[valueCount] = value
    inc valueCount
    current = nodes[3 * index + 2]
  if valueCount != int(nodeCount): return -1
  var checksum = 0'i64
  for nextIndex in 0 ..< valueCount:
    checksum += (int64(nextIndex) + 1) * (iteratorValues[nextIndex] + 100001)
  checksum
