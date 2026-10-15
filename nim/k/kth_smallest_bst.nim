const MaxNodeCount = 1023
const MaxValue = 10000'i64
const InvalidTreeResult = low(int64)

proc kthVisit(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    node: int64, remaining: ptr int64): int64 =
  if node == -1: return -1
  if node < 0 or uint64(node) >= uint64(nodeCount): return InvalidTreeResult
  let index = int(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if value < 0 or value > MaxValue or left < -1 or right < -1 or
      (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      (right >= 0 and uint64(right) >= uint64(nodeCount)): return InvalidTreeResult
  let leftResult = kthVisit(nodes, nodeCount, left, remaining)
  if leftResult >= 0 or leftResult == InvalidTreeResult: return leftResult
  dec remaining[]
  if remaining[] == 0: return value
  kthVisit(nodes, nodeCount, right, remaining)

proc kth_smallest_bst*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex, k: int64): int64 {.cdecl, exportc: "kth_smallest_bst".} =
  if nodeCount == 0 or nodeCount > MaxNodeCount or nodes == nil or rootIndex < 0 or
      uint64(rootIndex) >= uint64(nodeCount) or k < 1 or uint64(k) > uint64(nodeCount): return -1
  var remaining = k
  let result = kthVisit(nodes, nodeCount, rootIndex, addr remaining)
  if result < 0: return -1
  return result
