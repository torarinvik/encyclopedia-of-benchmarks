const MaxNodes = 256

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc avlHeight(root: int, left, right: var array[MaxNodes, int]): int =
  if root < 0: return 0
  1 + max(avlHeight(left[root], left, right), avlHeight(right[root], left, right))

proc avlBalance(root: int, left, right: var array[MaxNodes, int]): int =
  avlHeight(left[root], left, right) - avlHeight(right[root], left, right)

proc rotateRight(root: int, left, right: var array[MaxNodes, int]): int =
  let pivot = left[root]
  let moved = right[pivot]
  right[pivot] = root
  left[root] = moved
  pivot

proc rotateLeft(root: int, left, right: var array[MaxNodes, int]): int =
  let pivot = right[root]
  let moved = left[pivot]
  left[pivot] = root
  right[root] = moved
  pivot

proc insertNode(root: int, key: int32, keys: var array[MaxNodes, int32],
    left, right: var array[MaxNodes, int], nextNode: var int): int =
  if root < 0:
    let node = nextNode
    inc nextNode
    keys[node] = key
    left[node] = -1
    right[node] = -1
    return node
  if key < keys[root]:
    let child = left[root]
    left[root] = insertNode(child, key, keys, left, right, nextNode)
  else:
    let child = right[root]
    right[root] = insertNode(child, key, keys, left, right, nextNode)
  let balance = avlBalance(root, left, right)
  if balance > 1:
    if avlBalance(left[root], left, right) < 0:
      let child = left[root]
      left[root] = rotateLeft(child, left, right)
    return rotateRight(root, left, right)
  if balance < -1:
    if avlBalance(right[root], left, right) > 0:
      let child = right[root]
      right[root] = rotateRight(child, left, right)
    return rotateLeft(root, left, right)
  root

proc storeI32Le(output: ByteOutput, position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[position * 4 + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc emitInorder(root: int, keys: var array[MaxNodes, int32], left, right: var array[MaxNodes, int],
    output: ByteOutput, position: var int) =
  if root < 0: return
  emitInorder(left[root], keys, left, right, output, position)
  storeI32Le(output, position, keys[root])
  inc position
  emitInorder(right[root], keys, left, right, output, position)

proc avltree_cpp_insert_only*(input: I64Input, length: csize_t, output: ByteOutput,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "avltree_cpp_insert_only".} =
  if input.isNil or length < 2 or length > csize_t(MaxNodes + 1): return -1
  if input[0] < 1 or input[0] > MaxNodes: return -1
  let count = int(input[0])
  if int(length) != count + 1: return -1
  for index in 0 ..< count:
    let key = input[index + 1]
    if key < int64(low(int32)) or key > int64(high(int32)): return -1
    for previous in 0 ..< index:
      if input[previous + 1] == key: return -1
  let required = count * 4
  if output.isNil or int(outputCapacity) < required: return -2

  var keys: array[MaxNodes, int32]
  var left: array[MaxNodes, int]
  var right: array[MaxNodes, int]
  for index in 0 ..< MaxNodes:
    left[index] = -1
    right[index] = -1
  var nextNode = 0
  var root = -1
  for index in 0 ..< count:
    root = insertNode(root, int32(input[index + 1]), keys, left, right, nextNode)
  var position = 0
  emitInorder(root, keys, left, right, output, position)
  int64(position)
