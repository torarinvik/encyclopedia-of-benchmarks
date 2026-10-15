## Sum every node reachable from the root of a bounded indexed binary tree.
const InvalidResult = -9_000_000_000_000_000_000'i64

proc sumVisit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64, depth: csize_t): int64 =
  if node < 0 or uint64(node) >= uint64(nodeCount) or depth >= nodeCount: return InvalidResult
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < -1_000_000_000'i64 or value > 1_000_000_000'i64 or left < -1 or right < -1:
    return InvalidResult
  if (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return InvalidResult
  let leftSum = if left == -1: 0'i64 else: sumVisit(nodes, nodeCount, left, depth + 1)
  if leftSum == InvalidResult: return InvalidResult
  let rightSum = if right == -1: 0'i64 else: sumVisit(nodes, nodeCount, right, depth + 1)
  if rightSum == InvalidResult: return InvalidResult
  value + leftSum + rightSum

proc binary_tree_node_sum*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "binary_tree_node_sum".} =
  if nodes == nil or nodeCount == 0 or nodeCount > 900 or rootIndex < 0 or
      uint64(rootIndex) >= uint64(nodeCount): return InvalidResult
  sumVisit(nodes, nodeCount, rootIndex, 0)
