## Count nodes reachable from the root of a bounded indexed binary tree.
const InvalidResult = -9_000_000_000_000_000_000'i64

proc countVisit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64, depth: csize_t): int64 =
  if node < 0 or uint64(node) >= uint64(nodeCount) or depth >= nodeCount: return InvalidResult
  let index = csize_t(node)
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or right < -1:
    return InvalidResult
  if (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return InvalidResult
  let leftCount = if left == -1: 0'i64 else: countVisit(nodes, nodeCount, left, depth + 1)
  if leftCount == InvalidResult: return InvalidResult
  let rightCount = if right == -1: 0'i64 else: countVisit(nodes, nodeCount, right, depth + 1)
  if rightCount == InvalidResult: return InvalidResult
  1 + leftCount + rightCount

proc binary_tree_node_count*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "binary_tree_node_count".} =
  if nodes == nil or nodeCount == 0 or nodeCount > 900 or rootIndex < 0 or
      uint64(rootIndex) >= uint64(nodeCount): return InvalidResult
  countVisit(nodes, nodeCount, rootIndex, 0)
