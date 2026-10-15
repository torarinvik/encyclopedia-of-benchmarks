const
  MaxNodeCount = 257
  MaxNodeKeys = 15
  MaxNodeChildren = 16
  MaxKeyCount = 256
  MaxOperations = 511
  Offset = 1_000_000'i64
  HashMod = 1_000_000_007'i64

type
  BTree = object
    keys: array[MaxNodeCount, array[MaxNodeKeys, int64]]
    children: array[MaxNodeCount, array[MaxNodeChildren, int]]
    keyCount: array[MaxNodeCount, int]
    leaf: array[MaxNodeCount, bool]
    usedNodes: int
    root: int
    minDegree: int

proc splitChild(tree: var BTree, parent, childIndex: int): bool =
  if tree.usedNodes >= MaxNodeCount: return false
  let child = tree.children[parent][childIndex]
  let degree = tree.minDegree
  let sibling = tree.usedNodes
  inc tree.usedNodes
  tree.leaf[sibling] = tree.leaf[child]
  tree.keyCount[sibling] = degree - 1
  for i in 0 ..< degree - 1: tree.keys[sibling][i] = tree.keys[child][degree + i]
  if not tree.leaf[child]:
    for i in 0 ..< degree: tree.children[sibling][i] = tree.children[child][degree + i]
  let parentCount = tree.keyCount[parent]
  for i in countdown(parentCount + 1, childIndex + 2):
    tree.children[parent][i] = tree.children[parent][i - 1]
  tree.children[parent][childIndex + 1] = sibling
  for i in countdown(parentCount - 1, childIndex): tree.keys[parent][i + 1] = tree.keys[parent][i]
  tree.keys[parent][childIndex] = tree.keys[child][degree - 1]
  tree.keyCount[child] = degree - 1
  tree.keyCount[parent] = parentCount + 1
  true

proc insertNonFull(tree: var BTree, node: int, key: int64): bool =
  var index = tree.keyCount[node]
  if tree.leaf[node]:
    while index > 0 and key <= tree.keys[node][index - 1]:
      tree.keys[node][index] = tree.keys[node][index - 1]
      dec index
    tree.keys[node][index] = key
    inc tree.keyCount[node]
    return true
  while index > 0 and key <= tree.keys[node][index - 1]: dec index
  let child = tree.children[node][index]
  if tree.keyCount[child] == 2 * tree.minDegree - 1:
    if not splitChild(tree, node, index): return false
    if tree.keys[node][index] < key: inc index
  insertNonFull(tree, tree.children[node][index], key)

proc insertKey(tree: var BTree, key: int64): bool =
  if tree.keyCount[tree.root] == 2 * tree.minDegree - 1:
    if tree.usedNodes + 2 > MaxNodeCount: return false
    let oldRoot = tree.root
    let newRoot = tree.usedNodes
    inc tree.usedNodes
    tree.leaf[newRoot] = false
    tree.children[newRoot][0] = oldRoot
    tree.root = newRoot
    if not splitChild(tree, newRoot, 0): return false
  insertNonFull(tree, tree.root, key)

proc searchKey(tree: var BTree, key: int64): bool =
  var node = tree.root
  while true:
    var index = 0
    while index < tree.keyCount[node] and key > tree.keys[node][index]: inc index
    if index < tree.keyCount[node] and key == tree.keys[node][index]: return true
    if tree.leaf[node]: return false
    node = tree.children[node][index]

proc walkInOrder(tree: var BTree, operationCount: int, addOrderedSum: bool): tuple[hash, orderedSum: int64] =
  var nodeStack: array[32, int]
  var positionStack: array[32, int]
  var depth = 1
  var index = 0
  var hash = 0'i64
  var orderedSum = 0'i64
  nodeStack[0] = tree.root
  positionStack[0] = 0
  while depth > 0:
    let top = depth - 1
    let node = nodeStack[top]
    let count = tree.keyCount[node]
    if tree.leaf[node]:
      if positionStack[top] == count:
        dec depth
        continue
      let value = tree.keys[node][positionStack[top]]
      inc positionStack[top]
      hash = (hash * 257 + value + 1_000_001) mod HashMod
      if addOrderedSum: orderedSum += (int64(operationCount + index + 1) * (value + Offset))
      inc index
    elif positionStack[top] > 2 * count:
      dec depth
    else:
      let position = positionStack[top]
      inc positionStack[top]
      if position mod 2 == 0:
        nodeStack[depth] = tree.children[node][position div 2]
        positionStack[depth] = 0
        inc depth
      else:
        let value = tree.keys[node][position div 2]
        hash = (hash * 257 + value + 1_000_001) mod HashMod
        if addOrderedSum: orderedSum += (int64(operationCount + index + 1) * (value + Offset))
        inc index
  (hash, orderedSum)

proc b_tree_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "b_tree_benchmark".} =
  if values.isNil or length < 2 or length > 1024: return -1
  if values[0] < 2'i64 or values[0] > 8'i64 or values[1] < 0'i64 or values[1] > MaxOperations: return -1
  let operationCount = int(values[1])
  if int(length) != 2 + 2 * operationCount: return -1
  var tree: BTree
  tree.usedNodes = 1
  tree.root = 0
  tree.minDegree = int(values[0])
  tree.leaf[0] = true
  var keyCount = 0
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let opcode = values[2 + 2 * operation]
    let payload = values[3 + 2 * operation]
    var observed = 0'i64
    if opcode == 0:
      if payload < -Offset or payload > Offset or keyCount == MaxKeyCount or not insertKey(tree, payload): return -1
      inc keyCount
      observed = 1
    elif opcode == 1:
      if payload < -Offset or payload > Offset: return -1
      observed = int64(searchKey(tree, payload))
    elif opcode == 2:
      if payload != 0: return -1
      observed = walkInOrder(tree, 0, false).hash
    else:
      return -1
    checksum += int64(operation + 1) * (observed + Offset)
  checksum + walkInOrder(tree, operationCount, true).orderedSum
