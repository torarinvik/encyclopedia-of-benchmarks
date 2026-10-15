## Preserve recursive height calculation followed by recursive balance checks.
proc treeHeight(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64): int64 =
  if node == -1: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  let leftHeight = treeHeight(nodes, nodeCount, left)
  if leftHeight < 0: return -1
  let rightHeight = treeHeight(nodes, nodeCount, right)
  if rightHeight < 0: return -1
  1 + max(leftHeight, rightHeight)

proc balancedVisit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64): int64 =
  if node == -1: return 1
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  let leftHeight = treeHeight(nodes, nodeCount, left)
  if leftHeight < 0: return -1
  let rightHeight = treeHeight(nodes, nodeCount, right)
  if rightHeight < 0: return -1
  if abs(leftHeight - rightHeight) > 1: return 0
  let leftBalanced = balancedVisit(nodes, nodeCount, left)
  if leftBalanced <= 0: return leftBalanced
  balancedVisit(nodes, nodeCount, right)

proc balanced_binary_tree*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "balanced_binary_tree".} =
  if nodeCount > 1023: return -1
  if nodeCount == 0: return (if rootIndex == -1: 1 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  balancedVisit(nodes, nodeCount, rootIndex)
