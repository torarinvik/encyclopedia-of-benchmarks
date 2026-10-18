const MaxOperations = 64
const MaxLiveKeys = 32
const MaxInputLength = 1 + 2 * MaxOperations
const MaxParseableInputLength = MaxInputLength + 1
const MaxOutputBytes = 8 * (2 + MaxOperations + MaxLiveKeys)

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Node = object
    key: int64
    left: int32
    right: int32
    active: bool
  NodeArray = array[MaxLiveKeys, Node]

proc subtreeSize(nodes: var NodeArray, root: int32): int =
  if root < 0: return 0
  let index = int(root)
  1 + subtreeSize(nodes, nodes[index].left) + subtreeSize(nodes, nodes[index].right)

proc alphaHeight(nodes: var NodeArray, root: int32): int =
  var size = subtreeSize(nodes, root)
  var height = 0
  while size > 1:
    size = size shr 1
    inc height
  height

proc flatten(nodes: var NodeArray, root: int32, order: var array[MaxLiveKeys, int32], length: var int) =
  if root < 0: return
  let index = int(root)
  flatten(nodes, nodes[index].left, order, length)
  order[length] = root
  inc length
  flatten(nodes, nodes[index].right, order, length)

proc rebuild(nodes: var NodeArray, order: array[MaxLiveKeys, int32], start, finish: int): int32 =
  if start >= finish: return -1'i32
  let pivot = (start + finish) div 2
  let root = order[pivot]
  let index = int(root)
  nodes[index].left = rebuild(nodes, order, start, pivot)
  nodes[index].right = rebuild(nodes, order, pivot + 1, finish)
  root

proc findKey(nodes: var NodeArray, rootValue: int32, key: int64): bool =
  var root = rootValue
  while root >= 0:
    let index = int(root)
    if nodes[index].key == key: return true
    root = if key < nodes[index].key: nodes[index].left else: nodes[index].right
  false

proc allocateNode(nodes: var NodeArray, key: int64): int32 =
  for index in 0 ..< MaxLiveKeys:
    if not nodes[index].active:
      nodes[index] = Node(key: key, left: -1'i32, right: -1'i32, active: true)
      return int32(index)
  -1'i32

proc insertKey(nodes: var NodeArray, root: var int32, size, maxSize: var int, key: int64): bool =
  if root < 0:
    root = allocateNode(nodes, key)
    if root < 0: return false
    inc size
    maxSize = max(maxSize, size)
    return true
  var path: array[MaxLiveKeys, int32]
  var pathLength = 0
  var current = root
  while true:
    path[pathLength] = current
    inc pathLength
    let index = int(current)
    if nodes[index].key == key: return false
    if key < nodes[index].key:
      if nodes[index].left < 0:
        nodes[index].left = allocateNode(nodes, key)
        break
      current = nodes[index].left
    else:
      if nodes[index].right < 0:
        nodes[index].right = allocateNode(nodes, key)
        break
      current = nodes[index].right
  inc size
  maxSize = max(maxSize, size)
  if pathLength > alphaHeight(nodes, root):
    var depth = 1
    var scapegoat = -1'i32
    var parent = -1'i32
    while pathLength > 0:
      dec pathLength
      let candidate = path[pathLength]
      if depth > alphaHeight(nodes, candidate):
        scapegoat = candidate
        if pathLength > 0:
          dec pathLength
          parent = path[pathLength]
        break
      inc depth
    var order: array[MaxLiveKeys, int32]
    var orderLength = 0
    flatten(nodes, scapegoat, order, orderLength)
    let rebuilt = rebuild(nodes, order, 0, orderLength)
    if parent < 0: root = rebuilt
    elif nodes[int(parent)].key < nodes[int(rebuilt)].key: nodes[int(parent)].right = rebuilt
    else: nodes[int(parent)].left = rebuilt
  true

proc deleteKey(nodes: var NodeArray, root: var int32, size, maxSize: var int, key: int64): bool =
  var parent = -1'i32
  var node = root
  while node >= 0 and nodes[int(node)].key != key:
    parent = node
    let index = int(node)
    node = if key < nodes[index].key: nodes[index].left else: nodes[index].right
  if node < 0: return false
  let index = int(node)
  let left = nodes[index].left
  let right = nodes[index].right
  if left >= 0 and right >= 0:
    var predecessorParent = node
    var predecessor = left
    while nodes[int(predecessor)].right >= 0:
      predecessorParent = predecessor
      predecessor = nodes[int(predecessor)].right
    nodes[index].key = nodes[int(predecessor)].key
    let replacement = nodes[int(predecessor)].left
    if predecessorParent == node: nodes[index].left = replacement
    else: nodes[int(predecessorParent)].right = replacement
    nodes[int(predecessor)].active = false
    nodes[int(predecessor)].left = -1'i32
    nodes[int(predecessor)].right = -1'i32
  else:
    let replacement = if left >= 0: left else: right
    if parent < 0: root = replacement
    elif nodes[int(parent)].left == node: nodes[int(parent)].left = replacement
    else: nodes[int(parent)].right = replacement
    nodes[index].active = false
    nodes[index].left = -1'i32
    nodes[index].right = -1'i32
  dec size
  if root >= 0 and 2 * size < maxSize:
    var order: array[MaxLiveKeys, int32]
    var orderLength = 0
    flatten(nodes, root, order, orderLength)
    root = rebuild(nodes, order, 0, orderLength)
    maxSize = size
  true

proc rootWeightBalanced(nodes: var NodeArray, root: int32): bool =
  if root < 0: return true
  let index = int(root)
  let total = subtreeSize(nodes, root)
  2 * subtreeSize(nodes, nodes[index].left) <= total and
    2 * subtreeSize(nodes, nodes[index].right) <= total

proc putI64Le(output: U8Output, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 0xff'u64)
    bits = bits shr 8

proc scapegoat_tree*(input: I64Input, inputLength: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "scapegoat_tree".} =
  if input == nil or inputLength < 1 or inputLength > csize_t(MaxParseableInputLength): return -1
  if input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if int(inputLength) != 1 + 2 * operationCount: return -1

  var activeKeys: array[MaxLiveKeys, int64]
  var activeCount = 0
  for operation in 0 ..< operationCount:
    let offset = 1 + 2 * operation
    let opcode = input[offset]
    let key = input[offset + 1]
    if key < int64(low(int32)) or key > int64(high(int32)) or opcode < 0 or opcode > 6: return -1
    if opcode >= 3 and key != 0: return -1
    if opcode == 0:
      var present = false
      for i in 0 ..< activeCount:
        if activeKeys[i] == key: present = true
      if not present:
        if activeCount == MaxLiveKeys: return -1
        activeKeys[activeCount] = key
        inc activeCount
    elif opcode == 2:
      for i in 0 ..< activeCount:
        if activeKeys[i] == key:
          for j in i ..< activeCount - 1: activeKeys[j] = activeKeys[j + 1]
          dec activeCount
          break
    elif opcode == 6:
      activeCount = 0

  var nodes: NodeArray
  for index in 0 ..< MaxLiveKeys:
    nodes[index].left = -1'i32
    nodes[index].right = -1'i32
  var root = -1'i32
  var size = 0
  var maxSize = 0
  var results: array[MaxOperations, int64]
  for operation in 0 ..< operationCount:
    let offset = 1 + 2 * operation
    let opcode = input[offset]
    let key = input[offset + 1]
    if opcode == 0: results[operation] = if insertKey(nodes, root, size, maxSize, key): 1 else: 0
    elif opcode == 1: results[operation] = if findKey(nodes, root, key): 1 else: 0
    elif opcode == 2: results[operation] = if deleteKey(nodes, root, size, maxSize, key): 1 else: 0
    elif opcode == 3: results[operation] = int64(size)
    elif opcode == 4: results[operation] = int64(maxSize)
    elif opcode == 5: results[operation] = if rootWeightBalanced(nodes, root): 1 else: 0
    else:
      for index in 0 ..< MaxLiveKeys:
        nodes[index].active = false
        nodes[index].left = -1'i32
        nodes[index].right = -1'i32
      root = -1'i32
      size = 0
      maxSize = 0
      results[operation] = -2

  let outputBytes = (2 + operationCount + size) * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  var staged: array[MaxOutputBytes, uint8]
  putI64Le(cast[U8Output](addr staged[0]), 0, int64(operationCount))
  for operation in 0 ..< operationCount:
    putI64Le(cast[U8Output](addr staged[0]), (1 + operation) * 8, results[operation])
  putI64Le(cast[U8Output](addr staged[0]), (1 + operationCount) * 8, int64(size))
  var order: array[MaxLiveKeys, int32]
  var orderLength = 0
  flatten(nodes, root, order, orderLength)
  for i in 0 ..< orderLength:
    putI64Le(cast[U8Output](addr staged[0]), (2 + operationCount + i) * 8, nodes[int(order[i])].key)
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
