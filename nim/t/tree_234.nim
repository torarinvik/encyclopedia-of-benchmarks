const
  MaxOps = 128
  MaxNodes = 2049
  MaxOutputWords = 130

type
  TreeNode = object
    keys: array[3, int64]
    children: array[4, int]
    keyCount: int
    leaf: bool
  TreeContext = object
    nodes: array[MaxNodes, TreeNode]
    nodeCount: int
    root: int
    finalKeys: array[MaxOps, int64]
    finalCount: int

proc newNode(tree: var TreeContext, leaf: bool): int =
  result = tree.nodeCount
  inc tree.nodeCount
  tree.nodes[result].keyCount = 0
  tree.nodes[result].leaf = leaf
  for i in 0 ..< 4: tree.nodes[result].children[i] = -1

proc contains(tree: var TreeContext, nodeIndex: int, key: int64): bool =
  if nodeIndex < 0: return false
  let node = tree.nodes[nodeIndex]
  var i = 0
  while i < node.keyCount and key > node.keys[i]: inc i
  if i < node.keyCount and key == node.keys[i]: return true
  if node.leaf: return false
  contains(tree, node.children[i], key)

proc splitChild(tree: var TreeContext, parentIndex, childPosition: int) =
  let childIndex = tree.nodes[parentIndex].children[childPosition]
  let rightIndex = newNode(tree, tree.nodes[childIndex].leaf)
  let middle = tree.nodes[childIndex].keys[1]
  tree.nodes[rightIndex].keyCount = 1
  tree.nodes[rightIndex].keys[0] = tree.nodes[childIndex].keys[2]
  if not tree.nodes[childIndex].leaf:
    tree.nodes[rightIndex].children[0] = tree.nodes[childIndex].children[2]
    tree.nodes[rightIndex].children[1] = tree.nodes[childIndex].children[3]
  tree.nodes[childIndex].keyCount = 1
  let count = tree.nodes[parentIndex].keyCount
  for i in countdown(count, childPosition + 1):
    tree.nodes[parentIndex].keys[i] = tree.nodes[parentIndex].keys[i - 1]
  for i in countdown(count + 1, childPosition + 2):
    tree.nodes[parentIndex].children[i] = tree.nodes[parentIndex].children[i - 1]
  tree.nodes[parentIndex].keys[childPosition] = middle
  tree.nodes[parentIndex].children[childPosition + 1] = rightIndex
  inc tree.nodes[parentIndex].keyCount

proc insertNonfull(tree: var TreeContext, nodeIndex: int, key: int64) =
  var i = tree.nodes[nodeIndex].keyCount - 1
  if tree.nodes[nodeIndex].leaf:
    while i >= 0 and key < tree.nodes[nodeIndex].keys[i]:
      tree.nodes[nodeIndex].keys[i + 1] = tree.nodes[nodeIndex].keys[i]
      dec i
    tree.nodes[nodeIndex].keys[i + 1] = key
    inc tree.nodes[nodeIndex].keyCount
    return
  while i >= 0 and key < tree.nodes[nodeIndex].keys[i]: dec i
  inc i
  if tree.nodes[tree.nodes[nodeIndex].children[i]].keyCount == 3:
    splitChild(tree, nodeIndex, i)
    if key > tree.nodes[nodeIndex].keys[i]: inc i
  insertNonfull(tree, tree.nodes[nodeIndex].children[i], key)

proc insertKey(tree: var TreeContext, key: int64) =
  if contains(tree, tree.root, key): return
  if tree.root < 0:
    tree.root = newNode(tree, true)
    tree.nodes[tree.root].keys[0] = key
    tree.nodes[tree.root].keyCount = 1
    return
  if tree.nodes[tree.root].keyCount == 3:
    let oldRoot = tree.root
    let newRoot = newNode(tree, false)
    tree.nodes[newRoot].children[0] = oldRoot
    tree.root = newRoot
    splitChild(tree, newRoot, 0)
  insertNonfull(tree, tree.root, key)

proc findKey(node: TreeNode, key: int64): int =
  var i = 0
  while i < node.keyCount and node.keys[i] < key: inc i
  if i < node.keyCount and node.keys[i] == key: i else: -1

proc predecessor(tree: var TreeContext, nodeIndex: int): int64 =
  var idx = nodeIndex
  while not tree.nodes[idx].leaf: idx = tree.nodes[idx].children[tree.nodes[idx].keyCount]
  tree.nodes[idx].keys[tree.nodes[idx].keyCount - 1]

proc successor(tree: var TreeContext, nodeIndex: int): int64 =
  var idx = nodeIndex
  while not tree.nodes[idx].leaf: idx = tree.nodes[idx].children[0]
  tree.nodes[idx].keys[0]

proc mergeChildren(tree: var TreeContext, parentIndex, keyIndex: int): int =
  let leftIndex = tree.nodes[parentIndex].children[keyIndex]
  let rightIndex = tree.nodes[parentIndex].children[keyIndex + 1]
  let leftCount = tree.nodes[leftIndex].keyCount
  tree.nodes[leftIndex].keys[leftCount] = tree.nodes[parentIndex].keys[keyIndex]
  for i in 0 ..< tree.nodes[rightIndex].keyCount:
    tree.nodes[leftIndex].keys[leftCount + 1 + i] = tree.nodes[rightIndex].keys[i]
  if not tree.nodes[leftIndex].leaf:
    for i in 0 .. tree.nodes[rightIndex].keyCount:
      tree.nodes[leftIndex].children[leftCount + 1 + i] = tree.nodes[rightIndex].children[i]
  tree.nodes[leftIndex].keyCount = leftCount + 1 + tree.nodes[rightIndex].keyCount
  let parentCount = tree.nodes[parentIndex].keyCount
  for i in keyIndex ..< parentCount - 1:
    tree.nodes[parentIndex].keys[i] = tree.nodes[parentIndex].keys[i + 1]
  for i in keyIndex + 1 ..< parentCount:
    tree.nodes[parentIndex].children[i] = tree.nodes[parentIndex].children[i + 1]
  dec tree.nodes[parentIndex].keyCount
  leftIndex

proc borrowPrevious(tree: var TreeContext, parentIndex, childIndex: int) =
  let childNode = tree.nodes[parentIndex].children[childIndex]
  let siblingNode = tree.nodes[parentIndex].children[childIndex - 1]
  let childCount = tree.nodes[childNode].keyCount
  for i in countdown(childCount, 1): tree.nodes[childNode].keys[i] = tree.nodes[childNode].keys[i - 1]
  if not tree.nodes[childNode].leaf:
    for i in countdown(childCount + 1, 1): tree.nodes[childNode].children[i] = tree.nodes[childNode].children[i - 1]
    tree.nodes[childNode].children[0] = tree.nodes[siblingNode].children[tree.nodes[siblingNode].keyCount]
  tree.nodes[childNode].keys[0] = tree.nodes[parentIndex].keys[childIndex - 1]
  let siblingLast = tree.nodes[siblingNode].keyCount - 1
  tree.nodes[parentIndex].keys[childIndex - 1] = tree.nodes[siblingNode].keys[siblingLast]
  inc tree.nodes[childNode].keyCount
  dec tree.nodes[siblingNode].keyCount

proc borrowNext(tree: var TreeContext, parentIndex, childIndex: int) =
  let childNode = tree.nodes[parentIndex].children[childIndex]
  let siblingNode = tree.nodes[parentIndex].children[childIndex + 1]
  let childCount = tree.nodes[childNode].keyCount
  tree.nodes[childNode].keys[childCount] = tree.nodes[parentIndex].keys[childIndex]
  if not tree.nodes[childNode].leaf:
    tree.nodes[childNode].children[childCount + 1] = tree.nodes[siblingNode].children[0]
  tree.nodes[parentIndex].keys[childIndex] = tree.nodes[siblingNode].keys[0]
  let siblingCount = tree.nodes[siblingNode].keyCount
  for i in 0 ..< siblingCount - 1: tree.nodes[siblingNode].keys[i] = tree.nodes[siblingNode].keys[i + 1]
  if not tree.nodes[siblingNode].leaf:
    for i in 0 ..< siblingCount: tree.nodes[siblingNode].children[i] = tree.nodes[siblingNode].children[i + 1]
  inc tree.nodes[childNode].keyCount
  dec tree.nodes[siblingNode].keyCount

proc removeFromNode(tree: var TreeContext, nodeIndex: int, key: int64) =
  let keyIndex = findKey(tree.nodes[nodeIndex], key)
  if keyIndex >= 0:
    if tree.nodes[nodeIndex].leaf:
      let count = tree.nodes[nodeIndex].keyCount
      for i in keyIndex ..< count - 1: tree.nodes[nodeIndex].keys[i] = tree.nodes[nodeIndex].keys[i + 1]
      dec tree.nodes[nodeIndex].keyCount
      return
    let left = tree.nodes[nodeIndex].children[keyIndex]
    let right = tree.nodes[nodeIndex].children[keyIndex + 1]
    if tree.nodes[left].keyCount >= 2:
      let replacement = predecessor(tree, left)
      tree.nodes[nodeIndex].keys[keyIndex] = replacement
      removeFromNode(tree, left, replacement)
    elif tree.nodes[right].keyCount >= 2:
      let replacement = successor(tree, right)
      tree.nodes[nodeIndex].keys[keyIndex] = replacement
      removeFromNode(tree, right, replacement)
    else:
      let merged = mergeChildren(tree, nodeIndex, keyIndex)
      removeFromNode(tree, merged, key)
    return
  if tree.nodes[nodeIndex].leaf: return
  var childIndex = 0
  while childIndex < tree.nodes[nodeIndex].keyCount and key > tree.nodes[nodeIndex].keys[childIndex]: inc childIndex
  var childNode = tree.nodes[nodeIndex].children[childIndex]
  if tree.nodes[childNode].keyCount == 1:
    if childIndex > 0 and tree.nodes[tree.nodes[nodeIndex].children[childIndex - 1]].keyCount >= 2:
      borrowPrevious(tree, nodeIndex, childIndex)
    elif childIndex < tree.nodes[nodeIndex].keyCount and tree.nodes[tree.nodes[nodeIndex].children[childIndex + 1]].keyCount >= 2:
      borrowNext(tree, nodeIndex, childIndex)
    elif childIndex < tree.nodes[nodeIndex].keyCount:
      childNode = mergeChildren(tree, nodeIndex, childIndex)
    else:
      childNode = mergeChildren(tree, nodeIndex, childIndex - 1)
  removeFromNode(tree, childNode, key)

proc removeKey(tree: var TreeContext, key: int64): int64 =
  if not contains(tree, tree.root, key): return 0
  removeFromNode(tree, tree.root, key)
  if tree.root >= 0 and tree.nodes[tree.root].keyCount == 0:
    let oldRoot = tree.root
    tree.root = if tree.nodes[oldRoot].leaf: -1 else: tree.nodes[oldRoot].children[0]
  1

proc traverse(tree: var TreeContext, nodeIndex: int) =
  if nodeIndex < 0: return
  for i in 0 ..< tree.nodes[nodeIndex].keyCount:
    if not tree.nodes[nodeIndex].leaf: traverse(tree, tree.nodes[nodeIndex].children[i])
    tree.finalKeys[tree.finalCount] = tree.nodes[nodeIndex].keys[i]
    inc tree.finalCount
  if not tree.nodes[nodeIndex].leaf:
    traverse(tree, tree.nodes[nodeIndex].children[tree.nodes[nodeIndex].keyCount])

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc tree_234*(input: ptr UncheckedArray[int64], length: csize_t,
               output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "tree_234".} =
  if input.isNil or length < 1 or length > 258: return -1
  if input[0] < 0 or input[0] > MaxOps: return -1
  let ops = int(input[0])
  if int(length) != 1 + 2 * ops: return -1
  for i in 0 ..< ops:
    let op = input[1 + 2 * i]
    if op != 0 and op != 1: return -1
  var tree: TreeContext
  tree.root = -1
  var removeResults: array[MaxOps, int64]
  var removeCount = 0
  for i in 0 ..< ops:
    let op = input[1 + 2 * i]
    let key = input[2 + 2 * i]
    if op == 0: insertKey(tree, key)
    else:
      removeResults[removeCount] = removeKey(tree, key)
      inc removeCount
  traverse(tree, tree.root)
  var words: array[MaxOutputWords, int64]
  words[0] = int64(removeCount)
  for i in 0 ..< removeCount: words[1 + i] = removeResults[i]
  words[1 + removeCount] = int64(tree.finalCount)
  for i in 0 ..< tree.finalCount: words[2 + removeCount + i] = tree.finalKeys[i]
  let wordCount = 2 + removeCount + tree.finalCount
  let outputBytes = wordCount * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< wordCount: putI64(output, i * 8, words[i])
  int64(outputBytes)
