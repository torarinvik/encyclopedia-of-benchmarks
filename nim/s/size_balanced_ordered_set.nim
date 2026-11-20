const MaxOps = 128'i64
const MaxNodes = 129
const MaxInputLength = 257
const Missing = -1025'i64

type SizeBalancedTree = object
  key: array[MaxNodes, int64]
  size: array[MaxNodes, int]
  left: array[MaxNodes, int]
  right: array[MaxNodes, int]
  used: int

proc subtreeSize(tree: var SizeBalancedTree, node: int): int =
  if node == 0: 0 else: tree.size[node]

proc refresh(tree: var SizeBalancedTree, node: int) =
  tree.size[node] = subtreeSize(tree, tree.left[node]) + subtreeSize(tree, tree.right[node]) + 1

proc rotateRight(tree: var SizeBalancedTree, root: int): int =
  let pivot = tree.left[root]
  tree.left[root] = tree.right[pivot]
  tree.right[pivot] = root
  refresh(tree, root)
  refresh(tree, pivot)
  pivot

proc rotateLeft(tree: var SizeBalancedTree, root: int): int =
  let pivot = tree.right[root]
  tree.right[root] = tree.left[pivot]
  tree.left[pivot] = root
  refresh(tree, root)
  refresh(tree, pivot)
  pivot

proc maintain(tree: var SizeBalancedTree, rootInput: int, rightSide: bool): int =
  if rootInput == 0: return 0
  var root = rootInput
  if not rightSide:
    if subtreeSize(tree, tree.left[tree.left[root]]) > subtreeSize(tree, tree.right[root]):
      root = rotateRight(tree, root)
    elif subtreeSize(tree, tree.right[tree.left[root]]) > subtreeSize(tree, tree.right[root]):
      tree.left[root] = rotateLeft(tree, tree.left[root])
      root = rotateRight(tree, root)
    else:
      return root
  else:
    if subtreeSize(tree, tree.right[tree.right[root]]) > subtreeSize(tree, tree.left[root]):
      root = rotateLeft(tree, root)
    elif subtreeSize(tree, tree.left[tree.right[root]]) > subtreeSize(tree, tree.left[root]):
      tree.right[root] = rotateRight(tree, tree.right[root])
      root = rotateLeft(tree, root)
    else:
      return root
  tree.left[root] = maintain(tree, tree.left[root], false)
  tree.right[root] = maintain(tree, tree.right[root], true)
  root = maintain(tree, root, false)
  root = maintain(tree, root, true)
  root

proc insertKey(tree: var SizeBalancedTree, rootInput: int, key: int64): int =
  if rootInput == 0:
    inc tree.used
    tree.key[tree.used] = key
    tree.size[tree.used] = 1
    return tree.used
  var root = rootInput
  if key < tree.key[root]:
    tree.left[root] = insertKey(tree, tree.left[root], key)
    refresh(tree, root)
    root = maintain(tree, root, false)
  elif key > tree.key[root]:
    tree.right[root] = insertKey(tree, tree.right[root], key)
    refresh(tree, root)
    root = maintain(tree, root, true)
  root

proc rank(tree: var SizeBalancedTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var answer = 0'i64
  while root != 0:
    if key <= tree.key[root]:
      root = tree.left[root]
    else:
      answer += int64(subtreeSize(tree, tree.left[root]) + 1)
      root = tree.right[root]
  answer

proc kth(tree: var SizeBalancedTree, rootInput: int, indexInput: int64): int64 =
  var root = rootInput
  var index = indexInput
  while root != 0:
    let leftCount = int64(subtreeSize(tree, tree.left[root]))
    if index < leftCount: root = tree.left[root]
    elif index == leftCount: return tree.key[root]
    else:
      index -= leftCount + 1
      root = tree.right[root]
  Missing

proc predecessor(tree: var SizeBalancedTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var answer = Missing
  while root != 0:
    if tree.key[root] < key:
      answer = tree.key[root]
      root = tree.right[root]
    else:
      root = tree.left[root]
  answer

proc successor(tree: var SizeBalancedTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var answer = Missing
  while root != 0:
    if tree.key[root] > key:
      answer = tree.key[root]
      root = tree.left[root]
    else:
      root = tree.right[root]
  answer

proc size_balanced_ordered_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "size_balanced_ordered_set".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let q = input[0]
  if q < 0 or q > MaxOps or length != csize_t(1 + 2 * q): return -1
  for i in 0 ..< int(q):
    let op = input[1 + 2 * i]
    let arg = input[2 + 2 * i]
    if op < 0 or op > 4: return -1
    if op == 2:
      if arg < 0 or arg > 127: return -1
    elif arg < -1024 or arg > 1023:
      return -1

  var tree: SizeBalancedTree
  var root = 0
  var checksum = 0'i64
  for i in 0 ..< int(q):
    let op = input[1 + 2 * i]
    let arg = input[2 + 2 * i]
    var answer = 0'i64
    if op == 0:
      root = insertKey(tree, root, arg)
    else:
      if op == 1: answer = rank(tree, root, arg)
      elif op == 2: answer = kth(tree, root, arg)
      elif op == 3: answer = predecessor(tree, root, arg)
      else: answer = successor(tree, root, arg)
      checksum += int64(i + 1) * (answer - Missing)
  checksum
