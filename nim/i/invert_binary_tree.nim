## Recursively swap each node's children in a copied indexed binary tree.
const MaxNodeCount = 1023
const MaxTreeHeight = 512

proc validateSubtree(values: ptr UncheckedArray[int64], nodeCount: int, index: int64,
                     depth: int, visited: var array[MaxNodeCount, bool]): bool =
  if index == -1: return true
  if index < 0 or index >= int64(nodeCount) or depth > MaxTreeHeight: return false
  let node = int(index)
  if visited[node]: return false
  visited[node] = true
  let offset = 1 + 3 * node
  let value = values[offset]
  let left = values[offset + 1]
  let right = values[offset + 2]
  if value < -2_147_483_648 or value > 2_147_483_647 or left < -1 or right < -1 or
      left >= int64(nodeCount) or right >= int64(nodeCount): return false
  validateSubtree(values, nodeCount, left, depth + 1, visited) and
    validateSubtree(values, nodeCount, right, depth + 1, visited)

proc storeI64LittleEndian(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc emitMirroredSubtree(values: ptr UncheckedArray[int64], index: int64,
                         output: ptr UncheckedArray[uint8]) =
  if index == -1: return
  let inputOffset = 1 + 3 * int(index)
  let outputOffset = 24 * int(index)
  let left = values[inputOffset + 1]
  let right = values[inputOffset + 2]
  storeI64LittleEndian(output, outputOffset, values[inputOffset])
  storeI64LittleEndian(output, outputOffset + 8, right)
  storeI64LittleEndian(output, outputOffset + 16, left)
  emitMirroredSubtree(values, right, output)
  emitMirroredSubtree(values, left, output)

proc invert_binary_tree*(values: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "invert_binary_tree".} =
  if values == nil or length < 1 or (length - 1) mod 3 != 0 or length > 1 + 3 * MaxNodeCount: return -1
  let nodeCount = int((length - 1) div 3)
  let root = values[0]
  if nodeCount == 0: return if root == -1: 0 else: -1
  if root < 0 or root >= int64(nodeCount): return -1
  var visited: array[MaxNodeCount, bool]
  if not validateSubtree(values, nodeCount, root, 1, visited): return -1
  for index in 0 ..< nodeCount:
    if not visited[index]: return -1
  let required = csize_t(24 * nodeCount)
  if output == nil or outputCapacity < required: return -2
  emitMirroredSubtree(values, root, output)
  int64(nodeCount)
