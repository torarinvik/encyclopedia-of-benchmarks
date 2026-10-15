## Run unique-key AVL insert/search/delete operations and emit normalized output.
const MaxNodes = 128
const MaxOps = 128
type AvlNode = object
  key: int64
  left, right, height: int

proc nodeHeight(nodes: array[MaxNodes, AvlNode], index: int): int =
  if index < 0: 0 else: nodes[index].height

proc updateHeight(nodes: var array[MaxNodes, AvlNode], index: int) =
  nodes[index].height = 1 + max(nodeHeight(nodes, nodes[index].left), nodeHeight(nodes, nodes[index].right))

proc rotateRight(nodes: var array[MaxNodes, AvlNode], root: int): int =
  let pivot = nodes[root].left
  let middle = nodes[pivot].right
  nodes[pivot].right = root
  nodes[root].left = middle
  updateHeight(nodes, root)
  updateHeight(nodes, pivot)
  pivot

proc rotateLeft(nodes: var array[MaxNodes, AvlNode], root: int): int =
  let pivot = nodes[root].right
  let middle = nodes[pivot].left
  nodes[pivot].left = root
  nodes[root].right = middle
  updateHeight(nodes, root)
  updateHeight(nodes, pivot)
  pivot

proc rebalance(nodes: var array[MaxNodes, AvlNode], root: int): int =
  if root < 0: return root
  updateHeight(nodes, root)
  let balance = nodeHeight(nodes, nodes[root].left) - nodeHeight(nodes, nodes[root].right)
  if balance > 1:
    let left = nodes[root].left
    if nodeHeight(nodes, nodes[left].right) > nodeHeight(nodes, nodes[left].left):
      nodes[root].left = rotateLeft(nodes, left)
    return rotateRight(nodes, root)
  if balance < -1:
    let right = nodes[root].right
    if nodeHeight(nodes, nodes[right].left) > nodeHeight(nodes, nodes[right].right):
      nodes[root].right = rotateRight(nodes, right)
    return rotateLeft(nodes, root)
  root

proc insertNode(nodes: var array[MaxNodes, AvlNode], root: int, key: int64, next: var int): int =
  if root < 0:
    result = next
    inc next
    nodes[result] = AvlNode(key: key, left: -1, right: -1, height: 1)
    return
  if key < nodes[root].key:
    nodes[root].left = insertNode(nodes, nodes[root].left, key, next)
  else:
    nodes[root].right = insertNode(nodes, nodes[root].right, key, next)
  rebalance(nodes, root)

proc containsKey(nodes: array[MaxNodes, AvlNode], rootValue: int, key: int64): bool =
  var root = rootValue
  while root >= 0:
    if nodes[root].key == key: return true
    root = if key < nodes[root].key: nodes[root].left else: nodes[root].right
  false

proc maximumNode(nodes: array[MaxNodes, AvlNode], rootValue: int): int =
  result = rootValue
  while nodes[result].right >= 0: result = nodes[result].right

proc deleteNode(nodes: var array[MaxNodes, AvlNode], root: int, key: int64): int =
  if key < nodes[root].key:
    nodes[root].left = deleteNode(nodes, nodes[root].left, key)
  elif key > nodes[root].key:
    nodes[root].right = deleteNode(nodes, nodes[root].right, key)
  else:
    if nodes[root].left < 0: return nodes[root].right
    if nodes[root].right < 0: return nodes[root].left
    let predecessor = maximumNode(nodes, nodes[root].left)
    nodes[root].key = nodes[predecessor].key
    nodes[root].left = deleteNode(nodes, nodes[root].left, nodes[predecessor].key)
  rebalance(nodes, root)

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc avltree_unique_key_ops*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "avltree_unique_key_ops".} =
  if input.isNil or length < 1: return -1
  let operationCountValue = input[0]
  if operationCountValue < 0 or operationCountValue > MaxOps or length != csize_t(1 + 2 * operationCountValue): return -1
  let operationCount = int(operationCountValue)
  var active: array[MaxNodes, int64]
  var activeCount = 0
  var searchCount = 0
  for index in 0 ..< operationCount:
    let operation = input[1 + 2 * index]
    let key = input[2 + 2 * index]
    if operation < 0 or operation > 2 or key < -1_000_000 or key > 1_000_000: return -1
    var found = -1
    for i in 0 ..< activeCount:
      if active[i] == key: found = i
    if operation == 0:
      if found >= 0 or activeCount >= MaxNodes: return -1
      active[activeCount] = key
      inc activeCount
    elif operation == 1:
      inc searchCount
    else:
      if found < 0: return -1
      for i in found + 1 ..< activeCount: active[i - 1] = active[i]
      dec activeCount

  var nodes: array[MaxNodes, AvlNode]
  for i in 0 ..< MaxNodes:
    nodes[i].left = -1
    nodes[i].right = -1
  var root = -1
  var next = 0
  var results: array[MaxOps, int64]
  var resultCount = 0
  for index in 0 ..< operationCount:
    let operation = input[1 + 2 * index]
    let key = input[2 + 2 * index]
    if operation == 0:
      root = insertNode(nodes, root, key, next)
    elif operation == 1:
      results[resultCount] = if containsKey(nodes, root, key): 1'i64 else: 0'i64
      inc resultCount
    else:
      root = deleteNode(nodes, root, key)
  let bytes = (2 + activeCount + searchCount) * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  putI64(output, 0, int64(activeCount))
  var stack: array[MaxNodes, int]
  var top = 0
  var current = root
  var outIndex = 1
  while current >= 0 or top > 0:
    while current >= 0:
      stack[top] = current
      inc top
      current = nodes[current].left
    dec top
    current = stack[top]
    putI64(output, outIndex * 8, nodes[current].key)
    inc outIndex
    current = nodes[current].right
  putI64(output, outIndex * 8, int64(searchCount))
  inc outIndex
  for index in 0 ..< searchCount:
    putI64(output, outIndex * 8, results[index])
    inc outIndex
  int64(bytes)
