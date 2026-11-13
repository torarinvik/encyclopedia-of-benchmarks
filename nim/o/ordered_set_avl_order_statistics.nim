const MaxItems = 32'i64
const MaxOps = 32'i64
const MaxKey = 1000'i64

type AvlTree = object
  key: array[65, int64]
  height: array[65, int]
  size: array[65, int]
  left: array[65, int]
  right: array[65, int]
  used: int

proc nodeHeight(tree: var AvlTree, node: int): int =
  if node == 0: 0 else: tree.height[node]
proc nodeSize(tree: var AvlTree, node: int): int =
  if node == 0: 0 else: tree.size[node]
proc refresh(tree: var AvlTree, node: int) =
  let lh = nodeHeight(tree, tree.left[node])
  let rh = nodeHeight(tree, tree.right[node])
  tree.height[node] = (if lh > rh: lh else: rh) + 1
  tree.size[node] = nodeSize(tree, tree.left[node]) + nodeSize(tree, tree.right[node]) + 1
proc rotateRight(tree: var AvlTree, root: int): int =
  let pivot = tree.left[root]
  tree.left[root] = tree.right[pivot]
  tree.right[pivot] = root
  refresh(tree, root); refresh(tree, pivot)
  pivot
proc rotateLeft(tree: var AvlTree, root: int): int =
  let pivot = tree.right[root]
  tree.right[root] = tree.left[pivot]
  tree.left[pivot] = root
  refresh(tree, root); refresh(tree, pivot)
  pivot
proc rebalance(tree: var AvlTree, root: int): int =
  refresh(tree, root)
  let difference = nodeHeight(tree, tree.left[root]) - nodeHeight(tree, tree.right[root])
  if difference > 1:
    let child = tree.left[root]
    if nodeHeight(tree, tree.left[child]) < nodeHeight(tree, tree.right[child]):
      tree.left[root] = rotateLeft(tree, child)
    return rotateRight(tree, root)
  if difference < -1:
    let child = tree.right[root]
    if nodeHeight(tree, tree.right[child]) < nodeHeight(tree, tree.left[child]):
      tree.right[root] = rotateRight(tree, child)
    return rotateLeft(tree, root)
  root
proc insertKey(tree: var AvlTree, root: int, key: int64): int =
  if root == 0:
    inc tree.used
    tree.key[tree.used] = key
    tree.height[tree.used] = 1
    tree.size[tree.used] = 1
    return tree.used
  if key < tree.key[root]: tree.left[root] = insertKey(tree, tree.left[root], key)
  elif key > tree.key[root]: tree.right[root] = insertKey(tree, tree.right[root], key)
  else: return root
  rebalance(tree, root)
proc minimumNode(tree: var AvlTree, rootInput: int): int =
  var root = rootInput
  while tree.left[root] != 0: root = tree.left[root]
  root
proc eraseKey(tree: var AvlTree, root: int, key: int64): int =
  if root == 0: return 0
  if key < tree.key[root]: tree.left[root] = eraseKey(tree, tree.left[root], key)
  elif key > tree.key[root]: tree.right[root] = eraseKey(tree, tree.right[root], key)
  elif tree.left[root] == 0: return tree.right[root]
  elif tree.right[root] == 0: return tree.left[root]
  else:
    let next = minimumNode(tree, tree.right[root])
    tree.key[root] = tree.key[next]
    tree.right[root] = eraseKey(tree, tree.right[root], tree.key[next])
  rebalance(tree, root)
proc kth(tree: var AvlTree, rootInput: int, rankInput: int64): int64 =
  if rankInput < 1 or rankInput > int64(nodeSize(tree, rootInput)): return -1
  var root = rootInput
  var rank = rankInput
  while root != 0:
    let leftCount = int64(nodeSize(tree, tree.left[root]))
    if rank == leftCount + 1: return tree.key[root]
    if rank <= leftCount: root = tree.left[root]
    else:
      rank -= leftCount + 1
      root = tree.right[root]
  -1
proc countLe(tree: var AvlTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var count = 0'i64
  while root != 0:
    if tree.key[root] <= key:
      count += int64(nodeSize(tree, tree.left[root])) + 1
      root = tree.right[root]
    else: root = tree.left[root]
  count
proc predecessor(tree: var AvlTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var answer = -1'i64
  while root != 0:
    if tree.key[root] <= key:
      answer = tree.key[root]
      root = tree.right[root]
    else: root = tree.left[root]
  answer
proc successor(tree: var AvlTree, rootInput: int, key: int64): int64 =
  var root = rootInput
  var answer = -1'i64
  while root != 0:
    if tree.key[root] >= key:
      answer = tree.key[root]
      root = tree.left[root]
    else: root = tree.right[root]
  answer

proc ordered_set_avl_order_statistics*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ordered_set_avl_order_statistics".} =
  if input == nil or length < 2 or length > 99: return -1
  let n = input[0]
  let q = input[1]
  if n < 0 or n > MaxItems or q < 0 or q > MaxOps or length != csize_t(2 + n + 2 * q): return -1
  for i in 0 ..< int(n):
    let key = input[2 + i]
    if key < 0 or key > MaxKey or (i > 0 and input[1 + i] >= key): return -1
  for i in 0 ..< int(q):
    let op = input[int(2 + n) + 2 * i]
    let key = input[int(3 + n) + 2 * i]
    if op < 0 or op > 5 or key < 0 or key > MaxKey or (op == 2 and key < 1): return -1
  var tree: AvlTree
  var root = 0
  for i in 0 ..< int(n): root = insertKey(tree, root, input[2 + i])
  var checksum = 0'i64
  var queryIndex = 0'i64
  for i in 0 ..< int(q):
    let op = input[int(2 + n) + 2 * i]
    let key = input[int(3 + n) + 2 * i]
    if op == 0: root = insertKey(tree, root, key)
    elif op == 1: root = eraseKey(tree, root, key)
    else:
      var answer: int64
      if op == 2: answer = kth(tree, root, key)
      elif op == 3: answer = countLe(tree, root, key)
      elif op == 4: answer = predecessor(tree, root, key)
      else: answer = successor(tree, root, key)
      inc queryIndex
      checksum += queryIndex * (answer + 1)
  checksum
