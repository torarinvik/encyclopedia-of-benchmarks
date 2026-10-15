const MaxNodeCount = 1023
const MaxTreeHeight = 512

proc validate(nodes: ptr UncheckedArray[int64], count: int, index: int64,
              depth: int, visited: var array[MaxNodeCount, bool], seen: var int): bool =
  if index == -1: return true
  if index < 0 or index >= int64(count) or depth > MaxTreeHeight: return false
  let node = int(index)
  if visited[node]: return false
  visited[node] = true
  inc seen
  let off = 3 * node
  let value = nodes[off]
  let left = nodes[off + 1]
  let right = nodes[off + 2]
  if value < -2_147_483_648 or value > 2_147_483_647 or left < -1 or right < -1 or
      left >= int64(count) or right >= int64(count): return false
  validate(nodes, count, left, depth + 1, visited, seen) and
    validate(nodes, count, right, depth + 1, visited, seen)

proc flatten(nodes: ptr UncheckedArray[int64], index: int64) =
  if index == -1: return
  let off = 3 * int(index)
  let left = nodes[off + 1]
  flatten(nodes, left)
  let originalRight = nodes[off + 2]
  nodes[off + 2] = left
  nodes[off + 1] = -1
  var tail = index
  while nodes[3 * int(tail) + 2] != -1: tail = nodes[3 * int(tail) + 2]
  nodes[3 * int(tail) + 2] = originalRight
  flatten(nodes, originalRight)

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc flatten_binarytree_to_linkedlist*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if values == nil or length < 1 or (length - 1) mod 3 != 0 or length > 1 + 3 * MaxNodeCount: return -1
  let count = int((length - 1) div 3)
  let root = values[0]
  if count == 0: return if root == -1: 0 else: -1
  if root < 0 or root >= int64(count): return -1
  var nodes: array[3 * MaxNodeCount, int64]
  for i in 0 ..< 3 * count: nodes[i] = values[i + 1]
  var visited: array[MaxNodeCount, bool]
  var seen = 0
  if not validate(addr nodes[0], count, root, 1, visited, seen) or seen != count: return -1
  if output == nil or capacity < csize_t(24 * count): return -2
  flatten(addr nodes[0], root)
  for i in 0 ..< count:
    storeI64(output, 24 * i, nodes[3 * i])
    storeI64(output, 24 * i + 8, nodes[3 * i + 1])
    storeI64(output, 24 * i + 16, nodes[3 * i + 2])
  int64(count)
