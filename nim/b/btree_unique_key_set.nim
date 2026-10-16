const
  MinDegree = 255
  MaxNodeKeys = 2 * MinDegree - 1
  MaxNodeCount = 32
  MaxInserts = 2048
  MaxQueries = 1024
  MaxDeletes = 1024
  MaxOutputValues = 2 + MaxQueries + MaxInserts

type
  BTree = object
    keys: array[MaxNodeCount, array[MaxNodeKeys, int32]]
    children: array[MaxNodeCount, array[MaxNodeKeys + 1, int]]
    keyCount: array[MaxNodeCount, int]
    leaf: array[MaxNodeCount, bool]
    usedNodes: int
    root: int

proc newTree(): BTree =
  result.usedNodes = 1
  result.root = 0
  result.leaf[0] = true

proc searchKey(tree: BTree, key: int32): bool =
  var node = tree.root
  while true:
    var index = 0
    while index < tree.keyCount[node] and key > tree.keys[node][index]: inc index
    if index < tree.keyCount[node] and key == tree.keys[node][index]: return true
    if tree.leaf[node]: return false
    node = tree.children[node][index]

proc splitChild(tree: var BTree, parent, childIndex: int): bool =
  if tree.usedNodes >= MaxNodeCount: return false
  let child = tree.children[parent][childIndex]
  let sibling = tree.usedNodes
  inc tree.usedNodes
  tree.leaf[sibling] = tree.leaf[child]
  for i in 0 ..< MinDegree - 1:
    tree.keys[sibling][i] = tree.keys[child][i + MinDegree]
  if not tree.leaf[child]:
    for i in 0 ..< MinDegree:
      tree.children[sibling][i] = tree.children[child][i + MinDegree]
  tree.keyCount[sibling] = MinDegree - 1
  let parentCount = tree.keyCount[parent]
  var i = parentCount + 1
  while i > childIndex + 1:
    tree.children[parent][i] = tree.children[parent][i - 1]
    dec i
  tree.children[parent][childIndex + 1] = sibling
  i = parentCount
  while i > childIndex:
    tree.keys[parent][i] = tree.keys[parent][i - 1]
    dec i
  tree.keys[parent][childIndex] = tree.keys[child][MinDegree - 1]
  tree.keyCount[child] = MinDegree - 1
  tree.keyCount[parent] = parentCount + 1
  true

proc insertNonFull(tree: var BTree, node: int, key: int32): bool =
  var index = tree.keyCount[node]
  if tree.leaf[node]:
    while index > 0 and key < tree.keys[node][index - 1]:
      tree.keys[node][index] = tree.keys[node][index - 1]
      dec index
    tree.keys[node][index] = key
    inc tree.keyCount[node]
    return true
  while index > 0 and key < tree.keys[node][index - 1]: dec index
  if tree.keyCount[tree.children[node][index]] == MaxNodeKeys:
    if not tree.splitChild(node, index): return false
    if key > tree.keys[node][index]: inc index
  tree.insertNonFull(tree.children[node][index], key)

proc insertKey(tree: var BTree, key: int32): bool =
  if tree.keyCount[tree.root] == MaxNodeKeys:
    if tree.usedNodes >= MaxNodeCount: return false
    let oldRoot = tree.root
    let root = tree.usedNodes
    inc tree.usedNodes
    tree.leaf[root] = false
    tree.children[root][0] = oldRoot
    tree.root = root
    if not tree.splitChild(root, 0): return false
  tree.insertNonFull(tree.root, key)

proc predecessor(tree: BTree, start: int): int32 =
  var node = start
  while not tree.leaf[node]: node = tree.children[node][tree.keyCount[node]]
  tree.keys[node][tree.keyCount[node] - 1]

proc successor(tree: BTree, start: int): int32 =
  var node = start
  while not tree.leaf[node]: node = tree.children[node][0]
  tree.keys[node][0]

proc mergeChildren(tree: var BTree, parent, index: int) =
  let left = tree.children[parent][index]
  let right = tree.children[parent][index + 1]
  var leftCount = tree.keyCount[left]
  tree.keys[left][leftCount] = tree.keys[parent][index]
  inc leftCount
  for i in 0 ..< tree.keyCount[right]: tree.keys[left][leftCount + i] = tree.keys[right][i]
  if not tree.leaf[left]:
    for i in 0 .. tree.keyCount[right]: tree.children[left][leftCount + i] = tree.children[right][i]
  tree.keyCount[left] = leftCount + tree.keyCount[right]
  let parentCount = tree.keyCount[parent]
  for i in index + 1 ..< parentCount: tree.keys[parent][i - 1] = tree.keys[parent][i]
  for i in index + 2 .. parentCount: tree.children[parent][i - 1] = tree.children[parent][i]
  dec tree.keyCount[parent]

proc borrowPrevious(tree: var BTree, parent, index: int) =
  let child = tree.children[parent][index]
  let sibling = tree.children[parent][index - 1]
  let childCount = tree.keyCount[child]
  var i = childCount
  while i > 0:
    tree.keys[child][i] = tree.keys[child][i - 1]
    dec i
  if not tree.leaf[child]:
    i = childCount + 1
    while i > 0:
      tree.children[child][i] = tree.children[child][i - 1]
      dec i
  tree.keys[child][0] = tree.keys[parent][index - 1]
  if not tree.leaf[child]: tree.children[child][0] = tree.children[sibling][tree.keyCount[sibling]]
  tree.keys[parent][index - 1] = tree.keys[sibling][tree.keyCount[sibling] - 1]
  inc tree.keyCount[child]
  dec tree.keyCount[sibling]

proc borrowNext(tree: var BTree, parent, index: int) =
  let child = tree.children[parent][index]
  let sibling = tree.children[parent][index + 1]
  let childCount = tree.keyCount[child]
  let siblingCount = tree.keyCount[sibling]
  tree.keys[child][childCount] = tree.keys[parent][index]
  if not tree.leaf[child]: tree.children[child][childCount + 1] = tree.children[sibling][0]
  tree.keys[parent][index] = tree.keys[sibling][0]
  for i in 1 ..< siblingCount: tree.keys[sibling][i - 1] = tree.keys[sibling][i]
  if not tree.leaf[sibling]:
    for i in 1 .. siblingCount: tree.children[sibling][i - 1] = tree.children[sibling][i]
  inc tree.keyCount[child]
  dec tree.keyCount[sibling]

proc fillChild(tree: var BTree, parent, index: int) =
  if index > 0 and tree.keyCount[tree.children[parent][index - 1]] >= MinDegree:
    tree.borrowPrevious(parent, index)
  elif index < tree.keyCount[parent] and tree.keyCount[tree.children[parent][index + 1]] >= MinDegree:
    tree.borrowNext(parent, index)
  else:
    tree.mergeChildren(parent, (if index < tree.keyCount[parent]: index else: index - 1))

proc deleteFrom(tree: var BTree, node: int, key: int32): bool =
  var index = 0
  while index < tree.keyCount[node] and tree.keys[node][index] < key: inc index
  if index < tree.keyCount[node] and tree.keys[node][index] == key:
    if tree.leaf[node]:
      for i in index + 1 ..< tree.keyCount[node]: tree.keys[node][i - 1] = tree.keys[node][i]
      dec tree.keyCount[node]
    else:
      let left = tree.children[node][index]
      let right = tree.children[node][index + 1]
      if tree.keyCount[left] >= MinDegree:
        let replacement = tree.predecessor(left)
        tree.keys[node][index] = replacement
        return tree.deleteFrom(left, replacement)
      if tree.keyCount[right] >= MinDegree:
        let replacement = tree.successor(right)
        tree.keys[node][index] = replacement
        return tree.deleteFrom(right, replacement)
      tree.mergeChildren(node, index)
      return tree.deleteFrom(left, key)
    return true
  if tree.leaf[node]: return false
  let wasLast = index == tree.keyCount[node]
  if tree.keyCount[tree.children[node][index]] < MinDegree: tree.fillChild(node, index)
  if wasLast and index > tree.keyCount[node]: dec index
  tree.deleteFrom(tree.children[node][index], key)

proc deleteKey(tree: var BTree, key: int32): bool =
  if not tree.deleteFrom(tree.root, key): return false
  if tree.keyCount[tree.root] == 0 and not tree.leaf[tree.root]: tree.root = tree.children[tree.root][0]
  true

proc traverse(tree: BTree, node: int, result: var array[MaxOutputValues, int64], length: var int) =
  for i in 0 ..< tree.keyCount[node]:
    if not tree.leaf[node]: tree.traverse(tree.children[node][i], result, length)
    result[length] = int64(tree.keys[node][i])
    inc length
  if not tree.leaf[node]: tree.traverse(tree.children[node][tree.keyCount[node]], result, length)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc btree_unique_key_set*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "btree_unique_key_set".} =
  if input == nil or length < 3 or length > 4096: return -1
  let inputLength = int(length)
  if input[0] < 0 or input[0] > int64(MaxInserts): return -1
  let insertCount = int(input[0])
  let queryOffset = 1 + insertCount
  if queryOffset >= inputLength or input[queryOffset] < 0 or input[queryOffset] > int64(MaxQueries): return -1
  let queryCount = int(input[queryOffset])
  let deleteCountOffset = queryOffset + 1 + queryCount
  if deleteCountOffset >= inputLength or input[deleteCountOffset] < 0 or input[deleteCountOffset] > int64(MaxDeletes): return -1
  let deleteCount = int(input[deleteCountOffset])
  if inputLength != 3 + insertCount + queryCount + deleteCount: return -1

  var tree = newTree()
  for i in 0 ..< insertCount:
    let raw = input[1 + i]
    if raw < int64(int32.low) or raw > int64(int32.high): return -1
    let key = int32(raw)
    if tree.searchKey(key) or not tree.insertKey(key): return -1

  var result: array[MaxOutputValues, int64]
  var resultLength = 0
  result[resultLength] = int64(queryCount)
  inc resultLength
  let queryStart = queryOffset + 1
  for i in 0 ..< queryCount:
    let raw = input[queryStart + i]
    if raw < int64(int32.low) or raw > int64(int32.high): return -1
    result[resultLength] = (if tree.searchKey(int32(raw)): 1'i64 else: 0'i64)
    inc resultLength
  let deleteStart = deleteCountOffset + 1
  for i in 0 ..< deleteCount:
    let raw = input[deleteStart + i]
    if raw < int64(int32.low) or raw > int64(int32.high) or not tree.deleteKey(int32(raw)): return -1
  let countSlot = resultLength
  inc resultLength
  tree.traverse(tree.root, result, resultLength)
  result[countSlot] = int64(resultLength - countSlot - 1)
  let outputBytes = resultLength * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< resultLength: storeI64Le(output, i * 8, result[i])
  int64(outputBytes)
