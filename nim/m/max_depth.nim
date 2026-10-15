## Recursively return one plus the larger child depth for an indexed tree.
proc treeDepth(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64): int64 =
  if node == -1: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  let leftDepth = treeDepth(nodes, nodeCount, left)
  if leftDepth < 0: return -1
  let rightDepth = treeDepth(nodes, nodeCount, right)
  if rightDepth < 0: return -1
  1 + max(leftDepth, rightDepth)

proc max_depth*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "max_depth".} =
  if nodeCount > 1023: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  treeDepth(nodes, nodeCount, rootIndex)
