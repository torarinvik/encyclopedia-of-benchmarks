## Carry the largest downward gain upward and update the best path at each node.
const ErrorSentinel = -2_000_000_000'i64

proc maximumGain(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    node: int64, bestPath: ptr int64): int64 =
  if node == -1: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return ErrorSentinel
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < -1000 or value > 1000 or left < -1 or
      (left >= 0 and uint64(left) >= uint64(nodeCount)) or right < -1 or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return ErrorSentinel
  let leftGain = maximumGain(nodes, nodeCount, left, bestPath)
  if leftGain == ErrorSentinel: return ErrorSentinel
  let rightGain = maximumGain(nodes, nodeCount, right, bestPath)
  if rightGain == ErrorSentinel: return ErrorSentinel
  let positiveLeft = max(leftGain, 0'i64)
  let positiveRight = max(rightGain, 0'i64)
  let throughNode = value + positiveLeft + positiveRight
  if throughNode > bestPath[]: bestPath[] = throughNode
  value + max(positiveLeft, positiveRight)

proc binary_tree_maximum_path_sum*(nodes: ptr UncheckedArray[int64],
    nodeCount: csize_t, rootIndex: int64): int64 {.cdecl, exportc: "binary_tree_maximum_path_sum".} =
  if nodeCount == 0 or nodeCount > 1023 or nodes == nil or rootIndex < 0 or
      uint64(rootIndex) >= uint64(nodeCount): return -1
  var bestPath = -2_147_483_648'i64
  let gain = maximumGain(nodes, nodeCount, rootIndex, addr bestPath)
  if gain == ErrorSentinel: return -1
  bestPath
