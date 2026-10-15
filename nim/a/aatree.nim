const MaxOperations = 256

type
  AaNode = object
    key: int32
    left: int32
    right: int32
    level: int32
  AaTree = object
    nodes: array[MaxOperations, AaNode]
    used: int32

proc nodeLevel(tree: AaTree, node: int32): int32 =
  if node < 0: 0 else: tree.nodes[int(node)].level

proc contains(tree: AaTree, rootValue: int32, key: int32): bool =
  var root = rootValue
  while root >= 0:
    let node = tree.nodes[int(root)]
    if key < node.key: root = node.left
    elif key > node.key: root = node.right
    else: return true
  false

proc skew(tree: var AaTree, rootValue: int32): int32 =
  if rootValue < 0: return rootValue
  let root = int(rootValue)
  let leftChild = tree.nodes[root].left
  if leftChild < 0 or tree.nodes[int(leftChild)].level != tree.nodes[root].level: return rootValue
  tree.nodes[root].left = tree.nodes[int(leftChild)].right
  tree.nodes[int(leftChild)].right = rootValue
  leftChild

proc split(tree: var AaTree, rootValue: int32): int32 =
  if rootValue < 0: return rootValue
  let root = int(rootValue)
  let rightChild = tree.nodes[root].right
  if rightChild < 0: return rootValue
  let rightRight = tree.nodes[int(rightChild)].right
  if rightRight < 0 or tree.nodes[root].level != tree.nodes[int(rightRight)].level: return rootValue
  tree.nodes[root].right = tree.nodes[int(rightChild)].left
  tree.nodes[int(rightChild)].left = rootValue
  inc tree.nodes[int(rightChild)].level
  rightChild

proc insertNode(tree: var AaTree, rootValue: int32, key: int32): int32 =
  if rootValue < 0:
    let fresh = tree.used
    inc tree.used
    tree.nodes[int(fresh)] = AaNode(key: key, left: -1, right: -1, level: 1)
    return fresh
  let root = int(rootValue)
  if key < tree.nodes[root].key:
    let child = tree.nodes[root].left
    tree.nodes[root].left = insertNode(tree, child, key)
  else:
    let child = tree.nodes[root].right
    tree.nodes[root].right = insertNode(tree, child, key)
  split(tree, skew(tree, rootValue))

proc minimumNode(tree: AaTree, rootValue: int32): int32 =
  var root = rootValue
  while tree.nodes[int(root)].left >= 0: root = tree.nodes[int(root)].left
  root

proc maximumNode(tree: AaTree, rootValue: int32): int32 =
  var root = rootValue
  while tree.nodes[int(root)].right >= 0: root = tree.nodes[int(root)].right
  root

proc decreaseLevel(tree: var AaTree, rootValue: int32): int32 =
  let root = int(rootValue)
  let newLevel = min(nodeLevel(tree, tree.nodes[root].left), nodeLevel(tree, tree.nodes[root].right)) + 1
  if newLevel < tree.nodes[root].level:
    tree.nodes[root].level = newLevel
    let rightChild = tree.nodes[root].right
    if rightChild >= 0 and newLevel < tree.nodes[int(rightChild)].level:
      tree.nodes[int(rightChild)].level = newLevel
  rootValue

proc removeNode(tree: var AaTree, rootValue: int32, key: int32): int32 =
  let root = int(rootValue)
  if key < tree.nodes[root].key:
    let child = tree.nodes[root].left
    tree.nodes[root].left = removeNode(tree, child, key)
  elif key > tree.nodes[root].key:
    let child = tree.nodes[root].right
    tree.nodes[root].right = removeNode(tree, child, key)
  elif tree.nodes[root].left < 0 and tree.nodes[root].right < 0:
    return -1
  elif tree.nodes[root].left < 0:
    let successor = minimumNode(tree, tree.nodes[root].right)
    let successorKey = tree.nodes[int(successor)].key
    tree.nodes[root].key = successorKey
    let child = tree.nodes[root].right
    tree.nodes[root].right = removeNode(tree, child, successorKey)
  else:
    let predecessor = maximumNode(tree, tree.nodes[root].left)
    let predecessorKey = tree.nodes[int(predecessor)].key
    tree.nodes[root].key = predecessorKey
    let child = tree.nodes[root].left
    tree.nodes[root].left = removeNode(tree, child, predecessorKey)
  var currentRoot = skew(tree, decreaseLevel(tree, rootValue))
  let current = int(currentRoot)
  var rightChild = tree.nodes[current].right
  if rightChild >= 0:
    rightChild = skew(tree, rightChild)
    let rightRight = tree.nodes[int(rightChild)].right
    if rightRight >= 0: tree.nodes[int(rightChild)].right = skew(tree, rightRight)
    tree.nodes[current].right = rightChild
  currentRoot = split(tree, currentRoot)
  let newRoot = int(currentRoot)
  rightChild = tree.nodes[newRoot].right
  if rightChild >= 0: tree.nodes[newRoot].right = split(tree, rightChild)
  currentRoot

proc writeI32(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  output[offset] = uint8(bits and 255)
  output[offset + 1] = uint8((bits shr 8) and 255)
  output[offset + 2] = uint8((bits shr 16) and 255)
  output[offset + 3] = uint8((bits shr 24) and 255)

proc aatree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "aatree".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > MaxOperations: return -1
  let operationCount = int(input[0])
  if length != csize_t(1 + 2 * operationCount): return -1
  let outputBytes = 4 * operationCount
  if outputBytes > 0 and (output.isNil or capacity < csize_t(outputBytes)): return -2
  var tree: AaTree
  var root: int32 = -1
  var size = 0'i32
  for operation in 0 ..< operationCount:
    let opcode = input[1 + 2 * operation]
    let rawKey = input[2 + 2 * operation]
    if opcode < 0 or opcode > 4: return -1
    if opcode <= 2 and (rawKey < int64(low(int32)) or rawKey > int64(high(int32))): return -1
    if opcode >= 3 and rawKey != 0: return -1
    let key = int32(rawKey)
    var answer: int32
    if opcode == 0:
      if contains(tree, root, key): return -1
      root = insertNode(tree, root, key)
      inc size
      answer = size
    elif opcode == 1:
      if not contains(tree, root, key): return -1
      root = removeNode(tree, root, key)
      dec size
      answer = size
    elif opcode == 2:
      answer = int32(ord(contains(tree, root, key)))
    elif root < 0:
      return -1
    elif opcode == 3:
      answer = tree.nodes[int(minimumNode(tree, root))].key
    else:
      answer = tree.nodes[int(maximumNode(tree, root))].key
    writeI32(output, operation * 4, answer)
  int64(outputBytes)
