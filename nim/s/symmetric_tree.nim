## Recursively compare opposite child pairs in an indexed binary tree.
const MaxNodeCount = 1023

proc symmetricTreeMirror(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    left, right: int64): int64 =
  if left == -1 or right == -1:
    return if left == right: 1 else: 0
  if left < 0 or right < 0 or uint64(left) >= uint64(nodeCount) or uint64(right) >= uint64(nodeCount):
    return -1
  let leftNode = csize_t(left)
  let rightNode = csize_t(right)
  if nodes[3 * leftNode] != nodes[3 * rightNode]: return 0
  let leftLeft = nodes[3 * leftNode + 1]
  let leftRight = nodes[3 * leftNode + 2]
  let rightLeft = nodes[3 * rightNode + 1]
  let rightRight = nodes[3 * rightNode + 2]
  if leftLeft < -1 or (leftLeft >= 0 and uint64(leftLeft) >= uint64(nodeCount)) or
      leftRight < -1 or (leftRight >= 0 and uint64(leftRight) >= uint64(nodeCount)) or
      rightLeft < -1 or (rightLeft >= 0 and uint64(rightLeft) >= uint64(nodeCount)) or
      rightRight < -1 or (rightRight >= 0 and uint64(rightRight) >= uint64(nodeCount)):
    return -1
  let outer = symmetricTreeMirror(nodes, nodeCount, leftLeft, rightRight)
  if outer != 1: return outer
  symmetricTreeMirror(nodes, nodeCount, leftRight, rightLeft)

proc symmetric_tree*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "symmetric_tree".} =
  if nodeCount > MaxNodeCount: return -1
  if nodeCount == 0: return if rootIndex == -1: 1 else: -1
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  let root = csize_t(rootIndex)
  let left = nodes[3 * root + 1]
  let right = nodes[3 * root + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  symmetricTreeMirror(nodes, nodeCount, left, right)
