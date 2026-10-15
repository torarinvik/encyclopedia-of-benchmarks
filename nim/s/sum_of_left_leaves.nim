## Sum leaf values reached through left-child links.
const ErrorSentinel = -2_000_000_000'i64

proc visit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    node: int64, isLeft: bool): int64 =
  if node == -1: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return ErrorSentinel
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < -1000 or value > 1000 or left < -1 or
      (left >= 0 and uint64(left) >= uint64(nodeCount)) or right < -1 or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return ErrorSentinel
  if left == -1 and right == -1: return (if isLeft: value else: 0)
  let leftSum = visit(nodes, nodeCount, left, true)
  if leftSum == ErrorSentinel: return ErrorSentinel
  let rightSum = visit(nodes, nodeCount, right, false)
  if rightSum == ErrorSentinel: return ErrorSentinel
  leftSum + rightSum

proc sum_of_left_leaves*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "sum_of_left_leaves".} =
  if nodeCount > 1023: return -1
  if nodeCount == 0: return (if rootIndex == -1: 0 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  let result = visit(nodes, nodeCount, rootIndex, false)
  if result == ErrorSentinel: return -1
  result
