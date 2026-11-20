const MaxOps = 64'i64
const NodeCapacity = 129
const Missing = -129'i64
const MaxInputLength = 130

type WbltTree = object
  left: array[NodeCapacity, int]
  right: array[NodeCapacity, int]
  size: array[NodeCapacity, int]
  freeNext: array[NodeCapacity, int]
  key: array[NodeCapacity, int64]
  maximum: array[NodeCapacity, int64]
  nextNode: int
  freeHead: int

proc allocate(tree: var WbltTree): int =
  if tree.freeHead != 0:
    result = tree.freeHead
    tree.freeHead = tree.freeNext[result]
  else:
    result = tree.nextNode
    inc tree.nextNode
  tree.left[result] = 0
  tree.right[result] = 0
  tree.size[result] = 0
  tree.freeNext[result] = 0
  tree.key[result] = 0
  tree.maximum[result] = 0

proc release(tree: var WbltTree, node: int) =
  tree.left[node] = 0
  tree.right[node] = 0
  tree.size[node] = 0
  tree.key[node] = 0
  tree.maximum[node] = 0
  tree.freeNext[node] = tree.freeHead
  tree.freeHead = node

proc newLeaf(tree: var WbltTree, value: int64): int =
  result = tree.allocate()
  tree.key[result] = value
  tree.maximum[result] = value
  tree.size[result] = 1

proc join(tree: var WbltTree, a, b: int): int =
  result = tree.allocate()
  tree.left[result] = a
  tree.right[result] = b
  tree.size[result] = tree.size[a] + tree.size[b]
  tree.maximum[result] = tree.maximum[b]

proc merge(tree: var WbltTree, a, b: int): int

proc rebalance(tree: var WbltTree, node: int): int =
  if tree.size[node] == 1: return node
  let a = tree.left[node]
  let b = tree.right[node]
  if tree.size[a] > 3 * tree.size[b] or tree.size[b] > 3 * tree.size[a]:
    tree.release(node)
    return tree.merge(a, b)
  node

proc merge(tree: var WbltTree, a, b: int): int =
  if a == 0: return b
  if b == 0: return a
  if tree.size[a] > 3 * tree.size[b]:
    let x = tree.left[a]
    let y = tree.right[a]
    tree.release(a)
    let merged = tree.merge(y, b)
    let joined = tree.join(x, merged)
    return tree.rebalance(joined)
  if tree.size[b] > 3 * tree.size[a]:
    let x = tree.left[b]
    let y = tree.right[b]
    tree.release(b)
    let merged = tree.merge(a, x)
    let joined = tree.join(merged, y)
    return tree.rebalance(joined)
  tree.join(a, b)

proc insert(tree: var WbltTree, node: int, value: int64): int =
  if node == 0: return tree.newLeaf(value)
  if tree.size[node] == 1:
    let added = tree.newLeaf(value)
    if value <= tree.key[node]: return tree.join(added, node)
    return tree.join(node, added)
  if value <= tree.maximum[tree.left[node]]:
    tree.left[node] = tree.insert(tree.left[node], value)
  else:
    tree.right[node] = tree.insert(tree.right[node], value)
  tree.size[node] = tree.size[tree.left[node]] + tree.size[tree.right[node]]
  tree.maximum[node] = tree.maximum[tree.right[node]]
  tree.rebalance(node)

proc removeOne(tree: var WbltTree, node: int, value: int64, removed: var bool): int =
  removed = false
  if node == 0: return 0
  if tree.size[node] == 1:
    if tree.key[node] != value: return node
    tree.release(node)
    removed = true
    return 0
  if value <= tree.maximum[tree.left[node]]:
    tree.left[node] = tree.removeOne(tree.left[node], value, removed)
  else:
    tree.right[node] = tree.removeOne(tree.right[node], value, removed)
  if not removed: return node
  let a = tree.left[node]
  let b = tree.right[node]
  if a == 0 or b == 0:
    let child = if a != 0: a else: b
    tree.release(node)
    return child
  tree.size[node] = tree.size[a] + tree.size[b]
  tree.maximum[node] = tree.maximum[b]
  tree.rebalance(node)

proc rankLess(tree: WbltTree, node: int, value: int64): int64 =
  if node == 0: return 0
  if tree.size[node] == 1: return (if tree.key[node] < value: 1'i64 else: 0'i64)
  let a = tree.left[node]
  if value <= tree.maximum[a]: return tree.rankLess(a, value)
  int64(tree.size[a]) + tree.rankLess(tree.right[node], value)

proc kth(tree: WbltTree, nodeInput: int, indexInput: int64): int64 =
  if nodeInput == 0 or indexInput >= int64(tree.size[nodeInput]): return Missing
  var node = nodeInput
  var index = indexInput
  while tree.size[node] != 1:
    let a = tree.left[node]
    if index < int64(tree.size[a]): node = a
    else:
      index -= int64(tree.size[a])
      node = tree.right[node]
  tree.key[node]

proc predecessor(tree: WbltTree, node: int, value: int64): int64 =
  if node == 0: return Missing
  if tree.size[node] == 1: return (if tree.key[node] < value: tree.key[node] else: Missing)
  let a = tree.left[node]
  if value <= tree.maximum[a]: return tree.predecessor(a, value)
  let answer = tree.predecessor(tree.right[node], value)
  if answer == Missing: tree.maximum[a] else: answer

proc successor(tree: WbltTree, node: int, value: int64): int64 =
  if node == 0: return Missing
  if tree.size[node] == 1: return (if tree.key[node] > value: tree.key[node] else: Missing)
  let a = tree.left[node]
  if value < tree.maximum[a]: return tree.successor(a, value)
  tree.successor(tree.right[node], value)

proc weight_balanced_leaf_tree_order_statistics*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "weight_balanced_leaf_tree_order_statistics".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let q = input[0]
  if q < 0 or q > MaxOps or length != csize_t(1 + 2 * q): return -1
  for i in 0 ..< int(q):
    let op = input[1 + 2 * i]
    let arg = input[2 + 2 * i]
    if op < 0 or op > 5: return -1
    if op == 3:
      if arg < 0 or arg >= MaxOps: return -1
    elif arg < -128 or arg > 127:
      return -1

  var tree: WbltTree
  tree.nextNode = 1
  var root = 0
  var checksum = 0'i64
  for i in 0 ..< int(q):
    let op = input[1 + 2 * i]
    let arg = input[2 + 2 * i]
    if op == 0: root = tree.insert(root, arg)
    elif op == 1:
      var removed = false
      root = tree.removeOne(root, arg, removed)
    else:
      var answer = 0'i64
      if op == 2: answer = tree.rankLess(root, arg)
      elif op == 3: answer = tree.kth(root, arg)
      elif op == 4: answer = tree.predecessor(root, arg)
      else: answer = tree.successor(root, arg)
      checksum += int64(i + 1) * (answer - Missing)
  checksum
