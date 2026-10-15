## Check strict BST bounds over a valid indexed binary tree.
const
  MaxNodeCount = 1023
  ValueMin = -2147483648'i64
  ValueMax = 2147483647'i64

proc validateSubtree(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64,
    hasLower: bool, lower: int64, hasUpper: bool, upper: int64): int64 =
  if node == -1: return 1
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < ValueMin or value > ValueMax or
      left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  if (hasLower and value <= lower) or (hasUpper and value >= upper): return 0
  let leftResult = validateSubtree(nodes, nodeCount, left, hasLower, lower, true, value)
  if leftResult <= 0: return leftResult
  validateSubtree(nodes, nodeCount, right, true, value, hasUpper, upper)

proc validate_bst*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "validate_bst".} =
  if nodeCount > MaxNodeCount: return -1
  if nodeCount == 0: return (if rootIndex == -1: 1 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  validateSubtree(nodes, nodeCount, rootIndex, false, 0, false, 0)
