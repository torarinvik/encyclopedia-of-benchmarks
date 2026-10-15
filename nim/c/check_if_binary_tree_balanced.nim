proc balancedHeight(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    node: int64, balanced: ptr bool): int64 =
  if node == -1 or not balanced[]: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  let leftHeight = balancedHeight(nodes, nodeCount, left, balanced)
  if leftHeight < 0: return -1
  let rightHeight = balancedHeight(nodes, nodeCount, right, balanced)
  if rightHeight < 0: return -1
  if abs(leftHeight - rightHeight) > 1: balanced[] = false
  1 + max(leftHeight, rightHeight)

proc check_if_binary_tree_balanced*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "check_if_binary_tree_balanced".} =
  if nodeCount > 1023: return -1
  if nodeCount == 0: return (if rootIndex == -1: 1 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  var balanced = true
  let height = balancedHeight(nodes, nodeCount, rootIndex, addr balanced)
  if height < 0: return -1
  if balanced: 1 else: 0
