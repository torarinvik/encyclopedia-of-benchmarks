## Recursively check each node against its parent value.
proc isUnivalued(nodes: ptr UncheckedArray[int64], nodeCount: csize_t, node: int64): int64 =
  if node == -1: return 1
  if node < 0 or uint64(node) >= uint64(nodeCount): return -1
  let index = csize_t(node)
  let value = nodes[3 * index]
  let left = nodes[3 * index + 1]
  let right = nodes[3 * index + 2]
  if left < -1 or (left >= 0 and uint64(left) >= uint64(nodeCount)) or
      right < -1 or (right >= 0 and uint64(right) >= uint64(nodeCount)): return -1
  if (left >= 0 and nodes[3 * csize_t(left)] != value) or
      (right >= 0 and nodes[3 * csize_t(right)] != value): return 0
  let leftResult = isUnivalued(nodes, nodeCount, left)
  if leftResult <= 0: return leftResult
  isUnivalued(nodes, nodeCount, right)

proc univalued_binary_tree*(nodes: ptr UncheckedArray[int64], nodeCount: csize_t,
    rootIndex: int64): int64 {.cdecl, exportc: "univalued_binary_tree".} =
  if nodeCount > 1023: return -1
  if nodeCount == 0: return (if rootIndex == -1: 1 else: -1)
  if nodes == nil or rootIndex < 0 or uint64(rootIndex) >= uint64(nodeCount): return -1
  isUnivalued(nodes, nodeCount, rootIndex)
