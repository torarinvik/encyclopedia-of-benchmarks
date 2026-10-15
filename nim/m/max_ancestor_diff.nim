## Recursively carry the minimum and maximum ancestor values down each path.
proc visit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64,
    pathMin: int64, pathMax: int64): int64 =
  if node == -1: return 0
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let value = nodes[3 * index]
  if value < -100_000 or value > 100_000: return -1
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  var best = max(pathMin - value, value - pathMin)
  best = max(best, max(pathMax - value, value - pathMax))
  let low = min(pathMin, value)
  let high = max(pathMax, value)
  let leftBest = visit(nodes, nodeCount, left, low, high)
  if leftBest < 0: return -1
  let rightBest = visit(nodes, nodeCount, right, low, high)
  if rightBest < 0: return -1
  max(best, max(leftBest, rightBest))

proc max_ancestor_diff*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "max_ancestor_diff".} =
  if nodeCount == 0 or nodeCount > 1023 or nodes == nil or rootIndex < 0 or
      uint64(rootIndex) >= uint64(nodeCount): return -1
  let rootValue = nodes[3 * csize_t(rootIndex)]
  if rootValue < -100_000 or rootValue > 100_000: return -1
  visit(nodes, nodeCount, rootIndex, rootValue, rootValue)
