const MaxOps = 128
const MaxNodes = MaxOps + 1
type Node = object
  key, left, right: int
  priority: int64
proc priorityFor(key: int): int64 = (int64(key + 1_000_000) * 1_103_515_245'i64 + 12_345'i64) mod 2_147_483_648'i64
proc contains(nodes: var array[MaxNodes, Node], root, key: int): bool =
  if root == 0: return false
  if key == nodes[root].key: return true
  contains(nodes, (if key < nodes[root].key: nodes[root].left else: nodes[root].right), key)
proc rotateRight(nodes: var array[MaxNodes, Node], root: int): int =
  let p = nodes[root].left; nodes[root].left = nodes[p].right; nodes[p].right = root; p
proc rotateLeft(nodes: var array[MaxNodes, Node], root: int): int =
  let p = nodes[root].right; nodes[root].right = nodes[p].left; nodes[p].left = root; p
proc insertNode(nodes: var array[MaxNodes, Node], next: var int, root, key: int): int =
  if root == 0:
    result = next; inc next; nodes[result] = Node(key: key, priority: priorityFor(key)); return
  if key == nodes[root].key: return root
  if key < nodes[root].key:
    let child = insertNode(nodes, next, nodes[root].left, key); nodes[root].left = child
    if nodes[child].priority > nodes[root].priority: return rotateRight(nodes, root)
  else:
    let child = insertNode(nodes, next, nodes[root].right, key); nodes[root].right = child
    if nodes[child].priority > nodes[root].priority: return rotateLeft(nodes, root)
  root
proc merge(nodes: var array[MaxNodes, Node], left, right: int): int =
  if left == 0: return right
  if right == 0: return left
  if nodes[left].priority > nodes[right].priority:
    nodes[left].right = merge(nodes, nodes[left].right, right); return left
  nodes[right].left = merge(nodes, left, nodes[right].left); right
proc eraseNode(nodes: var array[MaxNodes, Node], root, key: int): int =
  if key < nodes[root].key: nodes[root].left = eraseNode(nodes, nodes[root].left, key); return root
  if key > nodes[root].key: nodes[root].right = eraseNode(nodes, nodes[root].right, key); return root
  merge(nodes, nodes[root].left, nodes[root].right)
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)
proc treap_unique_key_set*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "treap_unique_key_set".} =
  if input.isNil or length < 1 or input[0] < 0 or input[0] > MaxOps or int(length) != 1 + 2 * int(input[0]): return -1
  let ops = int(input[0])
  for i in 0 ..< ops:
    let op = input[1+2*i]; let key = input[2+2*i]
    if (op != 0 and op != 1) or key < -1_000_000 or key > 1_000_000: return -1
  var nodes: array[MaxNodes, Node]; var next = 1; var root = 0
  for i in 0 ..< ops:
    let op = int(input[1+2*i]); let key = int(input[2+2*i]); let present = contains(nodes, root, key)
    if (op == 0 and present) or (op == 1 and not present): return -1
    if op == 0: root = insertNode(nodes, next, root, key) else: root = eraseNode(nodes, root, key)
  var stack: array[MaxOps, int]; var top = 0; var current = root; var sorted: array[MaxOps, int64]; var count = 0
  while current != 0 or top > 0:
    while current != 0: stack[top] = current; inc top; current = nodes[current].left
    dec top; current = stack[top]; sorted[count] = int64(nodes[current].key); inc count; current = nodes[current].right
  let required = count * 8
  if output.isNil or int(capacity) < required: return -2
  for i in 0 ..< count: putI64(output, 8*i, sorted[i])
  int64(count)
