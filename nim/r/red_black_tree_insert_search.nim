const MaxOperations = 128
const InvalidResult = -1'i64
const CapacityResult = -2'i64

type
  Node = object
    key: int64
    left: int
    right: int
    red: bool
  TreeData = array[MaxOperations + 1, Node]
  KeyData = array[MaxOperations, int64]

proc isRed(tree: var TreeData, node: int): bool = node != 0 and tree[node].red

proc flipColors(tree: var TreeData, node: int) =
  tree[node].red = not tree[node].red
  let left = tree[node].left
  let right = tree[node].right
  tree[left].red = not tree[left].red
  tree[right].red = not tree[right].red

proc rotateLeft(tree: var TreeData, node: int): int =
  let pivot = tree[node].right
  tree[node].right = tree[pivot].left
  tree[pivot].left = node
  tree[pivot].red = tree[node].red
  tree[node].red = true
  pivot

proc rotateRight(tree: var TreeData, node: int): int =
  let pivot = tree[node].left
  tree[node].left = tree[pivot].right
  tree[pivot].right = node
  tree[pivot].red = tree[node].red
  tree[node].red = true
  pivot

proc insertNode(tree: var TreeData, node: int, key: int64, nextNode: var int): int =
  if node == 0:
    let created = nextNode
    inc nextNode
    tree[created] = Node(key: key, left: 0, right: 0, red: true)
    return created
  if isRed(tree, tree[node].left) and isRed(tree, tree[node].right): flipColors(tree, node)
  if key == tree[node].key: tree[node].key = key
  elif key < tree[node].key: tree[node].left = insertNode(tree, tree[node].left, key, nextNode)
  else: tree[node].right = insertNode(tree, tree[node].right, key, nextNode)
  if isRed(tree, tree[node].right) and not isRed(tree, tree[node].left): return rotateLeft(tree, node)
  if isRed(tree, tree[node].left) and isRed(tree, tree[tree[node].left].left): return rotateRight(tree, node)
  node

proc findNode(tree: var TreeData, start: int, key: int64): int =
  var node = start
  while node != 0:
    if key < tree[node].key: node = tree[node].left
    elif key > tree[node].key: node = tree[node].right
    else: return node
  0

proc insertionSort(values: var KeyData, count: int) =
  if count < 2: return
  for index in 1 ..< count:
    let value = values[index]
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value

proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc red_black_tree_insert_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "red_black_tree_insert_search".} =
  if input.isNil or length < 1: return InvalidResult
  let countValue = input[0]
  if countValue < 0 or countValue > MaxOperations or int(length) != 1 + 2 * int(countValue): return InvalidResult
  let operationCount = int(countValue)
  for op in 0 ..< operationCount:
    let opcode = input[1 + 2 * op]
    let key = input[2 + 2 * op]
    if (opcode != 0 and opcode != 1) or key < -2_147_483_648 or key > 2_147_483_647: return InvalidResult
  var tree: TreeData
  var keys: KeyData
  var searchResults: KeyData
  var root = 0
  var nextNode = 1
  var keyCount = 0
  var searchCount = 0
  for op in 0 ..< operationCount:
    let opcode = input[1 + 2 * op]
    let key = input[2 + 2 * op]
    if opcode == 0:
      if findNode(tree, root, key) != 0: return InvalidResult
      root = insertNode(tree, root, key, nextNode)
      tree[root].red = false
      keys[keyCount] = key
      inc keyCount
    else:
      searchResults[searchCount] = if findNode(tree, root, key) != 0: 1 else: 0
      inc searchCount
  insertionSort(keys, keyCount)
  let required = (2 + keyCount + searchCount) * 8
  if output.isNil or int(capacity) < required: return CapacityResult
  var offset = 0
  writeI64Le(output, offset, int64(keyCount)); offset += 8
  for index in 0 ..< keyCount:
    writeI64Le(output, offset, keys[index]); offset += 8
  writeI64Le(output, offset, int64(searchCount)); offset += 8
  for index in 0 ..< searchCount:
    writeI64Le(output, offset, searchResults[index]); offset += 8
  int64(required)
