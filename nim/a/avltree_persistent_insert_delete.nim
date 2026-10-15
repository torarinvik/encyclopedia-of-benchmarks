const MaxOps = 32
const PoolCap = 8192
const OutCap = 5000
type Node = object
  value, left, right, height: int

proc nodeHeight(pool: var array[PoolCap, Node], id: int): int =
  if id == 0: -1 else: pool[id].height
proc makeNode(pool: var array[PoolCap, Node], next: var int, value, left, right: int): int =
  result = next; inc next
  pool[result] = Node(value: value, left: left, right: right, height: 1 + max(nodeHeight(pool, left), nodeHeight(pool, right)))
proc balance(pool: var array[PoolCap, Node], id: int): int = nodeHeight(pool, pool[id].right) - nodeHeight(pool, pool[id].left)
proc rotateRight(pool: var array[PoolCap, Node], next: var int, root: int): int =
  let left = pool[root].left
  let moved = makeNode(pool, next, pool[root].value, pool[left].right, pool[root].right)
  makeNode(pool, next, pool[left].value, pool[left].left, moved)
proc rotateLeft(pool: var array[PoolCap, Node], next: var int, root: int): int =
  let right = pool[root].right
  let moved = makeNode(pool, next, pool[root].value, pool[root].left, pool[right].left)
  makeNode(pool, next, pool[right].value, moved, pool[right].right)
proc rebalance(pool: var array[PoolCap, Node], next: var int, root: int): int =
  let bf = balance(pool, root)
  if bf > 1:
    if balance(pool, pool[root].right) < 0:
      let rotated = rotateRight(pool, next, pool[root].right)
      let nr = makeNode(pool, next, pool[root].value, pool[root].left, rotated)
      return rotateLeft(pool, next, nr)
    return rotateLeft(pool, next, root)
  if bf < -1:
    if balance(pool, pool[root].left) > 0:
      let rotated = rotateLeft(pool, next, pool[root].left)
      let nr = makeNode(pool, next, pool[root].value, rotated, pool[root].right)
      return rotateRight(pool, next, nr)
    return rotateRight(pool, next, root)
  root
proc insertNode(pool: var array[PoolCap, Node], next: var int, root, value: int): int =
  if root == 0: return makeNode(pool, next, value, 0, 0)
  let n = pool[root]
  if value == n.value: return root
  if value < n.value:
    let left = insertNode(pool, next, n.left, value)
    return rebalance(pool, next, makeNode(pool, next, n.value, left, n.right))
  let right = insertNode(pool, next, n.right, value)
  rebalance(pool, next, makeNode(pool, next, n.value, n.left, right))
proc deleteMin(pool: var array[PoolCap, Node], next: var int, root: int, minimum: var int): int =
  let n = pool[root]
  if n.left == 0: minimum = n.value; return n.right
  let left = deleteMin(pool, next, n.left, minimum)
  rebalance(pool, next, makeNode(pool, next, n.value, left, n.right))
proc deleteNode(pool: var array[PoolCap, Node], next: var int, root, value: int): int =
  if root == 0: return 0
  let n = pool[root]
  if value < n.value: return rebalance(pool, next, makeNode(pool, next, n.value, deleteNode(pool, next, n.left, value), n.right))
  if value > n.value: return rebalance(pool, next, makeNode(pool, next, n.value, n.left, deleteNode(pool, next, n.right, value)))
  if n.left == 0: return n.right
  if n.right == 0: return n.left
  var successor = 0
  let right = deleteMin(pool, next, n.right, successor)
  rebalance(pool, next, makeNode(pool, next, successor, n.left, right))

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc avltree_persistent_insert_delete*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "avltree_persistent_insert_delete".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > MaxOps or int(length) != 1 + 3 * int(input[0]): return -1
  let operations = int(input[0])
  for i in 0 ..< operations:
    let parent = input[1 + 3*i]; let op = input[2 + 3*i]; let value = input[3 + 3*i]
    if parent < 0 or parent > i or (op != 0 and op != 1) or value < -1000 or value > 1000: return -1
  var pool: array[PoolCap, Node]; var next = 1; var roots: array[MaxOps + 1, int]
  for i in 0 ..< operations:
    let root = roots[int(input[1 + 3*i])]
    roots[i+1] = if input[2+3*i] == 0: insertNode(pool, next, root, int(input[3+3*i])) else: deleteNode(pool, next, root, int(input[3+3*i]))
    if next >= PoolCap - 64: return -1
  var packed: array[OutCap, int64]; var used = 0
  packed[used] = int64(operations + 1); inc used
  for version in 0 .. operations:
    let root = roots[version]
    var queue: array[MaxOps + 1, int]; var local: array[PoolCap, int]; var leftIds, rightIds: array[MaxOps + 1, int]
    for i in 0 ..< PoolCap: local[i] = -1
    var tail = 0
    if root != 0: queue[0] = root; local[root] = 0; tail = 1
    for head in 0 ..< tail:
      leftIds[head] = -1; rightIds[head] = -1
      let children = [pool[queue[head]].left, pool[queue[head]].right]
      for side in 0 ..< 2:
        let child = children[side]
        if child != 0:
          if local[child] < 0: local[child] = tail; queue[tail] = child; inc tail
          if side == 0: leftIds[head] = local[child] else: rightIds[head] = local[child]
    packed[used] = int64(tail); inc used; packed[used] = int64(nodeHeight(pool, root)); inc used
    for i in 0 ..< tail:
      let n = pool[queue[i]]
      for value in [int64(n.value), int64(n.height), int64(leftIds[i]), int64(rightIds[i])]: packed[used] = value; inc used
  let required = used * 8
  if output.isNil or int(capacity) < required: return -2
  for i in 0 ..< used: putI64(output, 8*i, packed[i])
  int64(required)
