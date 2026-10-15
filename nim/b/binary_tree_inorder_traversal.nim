const MaxNodeCount = 100

proc inorderVisit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64,
    output: ptr UncheckedArray[int64], capacity: csize_t, used: ptr csize_t): bool =
  if node == -1: return true
  if node < 0 or uint64(node) >= uint64(nodeCount): return false
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < -100 or value > 100 or left < -1 or right < -1 or
      (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return false
  if not inorderVisit(nodes, nodeCount, left, output, capacity, used): return false
  if used[] >= capacity: return false
  output[used[]] = value
  inc used[]
  inorderVisit(nodes, nodeCount, right, output, capacity, used)

proc binary_tree_inorder_traversal*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64, output: ptr UncheckedArray[int64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_tree_inorder_traversal".} =
  if nodeCount > MaxNodeCount or outputCapacity < nodeCount: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or output == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  var used = csize_t(0)
  if not inorderVisit(nodes, nodeCount, rootIndex, output, outputCapacity, addr used): return -1
  if used != nodeCount: return -1
  return int64(used)
