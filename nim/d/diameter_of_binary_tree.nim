## Count the path through the selected node, matching Node.diameter().
const MaxNodeCount = 1023
const ErrorSentinel = -2_000_000_000'i64

proc heightAndCheck(nodes: ptr UncheckedArray[int64], nodeCount: int, node: int64,
    seen: var array[MaxNodeCount, bool], visited: var int): int64 =
  if node == -1: return 0
  if node < 0 or node >= int64(nodeCount): return ErrorSentinel
  let index = int(node)
  if seen[index]: return ErrorSentinel
  seen[index] = true
  inc visited
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or right < -1 or left >= int64(nodeCount) or right >= int64(nodeCount): return ErrorSentinel
  let leftHeight = heightAndCheck(nodes, nodeCount, left, seen, visited)
  if leftHeight == ErrorSentinel: return ErrorSentinel
  let rightHeight = heightAndCheck(nodes, nodeCount, right, seen, visited)
  if rightHeight == ErrorSentinel: return ErrorSentinel
  1 + max(leftHeight, rightHeight)

proc diameter_of_binary_tree*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "diameter_of_binary_tree".} =
  if nodes == nil or nodeCount < 1 or nodeCount > MaxNodeCount or
      rootIndex < 0 or rootIndex >= int64(nodeCount): return -1
  let count = int(nodeCount)
  let root = int(rootIndex)
  let left = nodes[3 * root + 1]
  let right = nodes[3 * root + 2]
  if left < -1 or right < -1 or left >= int64(count) or right >= int64(count): return -1
  var seen: array[MaxNodeCount, bool]
  seen[root] = true
  var visited = 1
  let leftHeight = heightAndCheck(nodes, count, left, seen, visited)
  if leftHeight == ErrorSentinel: return -1
  let rightHeight = heightAndCheck(nodes, count, right, seen, visited)
  if rightHeight == ErrorSentinel or visited != count: return -1
  leftHeight + rightHeight + 1
