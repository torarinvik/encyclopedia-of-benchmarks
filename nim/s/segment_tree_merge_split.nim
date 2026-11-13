const
  Domain = 64
  MaxQ = 32
  MaxRoots = 33
  MaxNodes = 1024
  MaxInput = 131
  MaxOutput = 256

type
  Node = object
    left, right: int32
    total: int64
  Operation = object
    op, a, b, c: int64

proc newNode(nodes: var array[MaxNodes, Node], used: var int): int32 =
  if used >= MaxNodes: return -1
  result = int32(used)
  inc used
  nodes[int(result)] = Node()

proc insert(nodes: var array[MaxNodes, Node], used: var int, nodeValue: int32,
            lo, hi, value: int, amount: int64): int32 =
  var node = nodeValue
  if node == 0:
    node = newNode(nodes, used)
    if node < 0: return -1
  let index = int(node)
  if lo == hi:
    nodes[index].total += amount
    return node
  let mid = (lo + hi) div 2
  if value <= mid:
    let child = insert(nodes, used, nodes[index].left, lo, mid, value, amount)
    if child < 0: return -1
    nodes[index].left = child
  else:
    let child = insert(nodes, used, nodes[index].right, mid + 1, hi, value, amount)
    if child < 0: return -1
    nodes[index].right = child
  nodes[index].total = nodes[int(nodes[index].left)].total + nodes[int(nodes[index].right)].total
  node

proc mergeNodes(nodes: var array[MaxNodes, Node], a, b: int32, lo, hi: int): int32 =
  if a == 0: return b
  if b == 0: return a
  let ai = int(a)
  let bi = int(b)
  if lo == hi:
    nodes[ai].total += nodes[bi].total
    return a
  let mid = (lo + hi) div 2
  let al = nodes[ai].left
  let ar = nodes[ai].right
  let bl = nodes[bi].left
  let br = nodes[bi].right
  nodes[ai].left = mergeNodes(nodes, al, bl, lo, mid)
  nodes[ai].right = mergeNodes(nodes, ar, br, mid + 1, hi)
  nodes[ai].total = nodes[int(nodes[ai].left)].total + nodes[int(nodes[ai].right)].total
  a

proc split(nodes: var array[MaxNodes, Node], used: var int, node: int32,
           lo, hi, ql, qr: int): tuple[remain, moved: int32] =
  if node == 0 or qr < lo or hi < ql: return (node, 0)
  if ql <= lo and hi <= qr: return (0, node)
  let index = int(node)
  let mid = (lo + hi) div 2
  let (remainLeft, movedLeft) = split(nodes, used, nodes[index].left, lo, mid, ql, qr)
  if remainLeft < 0: return (-1, 0)
  let (remainRight, movedRight) = split(nodes, used, nodes[index].right, mid + 1, hi, ql, qr)
  if remainRight < 0: return (-1, 0)
  nodes[index].left = remainLeft
  nodes[index].right = remainRight
  nodes[index].total = nodes[int(remainLeft)].total + nodes[int(remainRight)].total
  var moved: int32 = 0
  if movedLeft != 0 or movedRight != 0:
    moved = newNode(nodes, used)
    if moved < 0: return (-1, 0)
    nodes[int(moved)].left = movedLeft
    nodes[int(moved)].right = movedRight
    nodes[int(moved)].total = nodes[int(movedLeft)].total + nodes[int(movedRight)].total
  (node, moved)

proc rangeSum(nodes: var array[MaxNodes, Node], node: int32,
              lo, hi, ql, qr: int): int64 =
  if node == 0 or qr < lo or hi < ql: return 0
  let index = int(node)
  if ql <= lo and hi <= qr: return nodes[index].total
  let mid = (lo + hi) div 2
  rangeSum(nodes, nodes[index].left, lo, mid, ql, qr) +
    rangeSum(nodes, nodes[index].right, mid + 1, hi, ql, qr)

proc kth(nodes: var array[MaxNodes, Node], node: int32, lo, hi: int, k: int64): int64 =
  if node == 0 or k > nodes[int(node)].total: return -1
  if lo == hi: return int64(lo)
  let index = int(node)
  let mid = (lo + hi) div 2
  let leftNode = nodes[index].left
  if k <= nodes[int(leftNode)].total:
    return kth(nodes, leftNode, lo, mid, k)
  kth(nodes, nodes[index].right, mid + 1, hi, k - nodes[int(leftNode)].total)

proc packI64(output: var array[MaxOutput, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc segment_tree_merge_split*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "segment_tree_merge_split".} =
  if input == nil or length < 2 or length > MaxInput.csize_t: return -1
  if input[0] != Domain.int64 or input[1] < 0 or input[1] > MaxQ.int64: return -1
  let q = int(input[1])
  if length != csize_t(2 + 4 * q): return -1

  var operations: array[MaxQ, Operation]
  var rootsCount = 1
  for i in 0 ..< q:
    let base = 2 + 4 * i
    let op = input[base]
    let a = input[base + 1]
    let b = input[base + 2]
    let c = input[base + 3]
    let aOk = a >= 0 and a < int64(rootsCount)
    let bOk = b >= 0 and b < int64(rootsCount)
    var valid = false
    if op == 0:
      valid = aOk and b >= 1 and b <= Domain.int64 and c >= 1 and c <= 10
    elif op == 1:
      valid = aOk and b >= 1 and b <= c and c <= Domain.int64 and rootsCount < MaxRoots
      if valid: inc rootsCount
    elif op == 2:
      valid = aOk and bOk and a != b and c == 0
    elif op == 3:
      valid = aOk and b >= 1 and b <= c and c <= Domain.int64
    elif op == 4:
      valid = aOk and b >= 1 and b <= 320 and c == 0
    if not valid: return -1
    operations[i] = Operation(op: op, a: a, b: b, c: c)

  var nodes: array[MaxNodes, Node]
  var roots: array[MaxRoots, int32]
  var staged: array[MaxOutput, uint8]
  var used = 1
  var rootCount = 1
  var bytes = 0
  for i in 0 ..< q:
    let item = operations[i]
    let a = int(item.a)
    let b = int(item.b)
    let c = int(item.c)
    if item.op == 0:
      let updated = insert(nodes, used, roots[a], 1, Domain, b, item.c)
      if updated < 0: return -1
      roots[a] = updated
    elif item.op == 1:
      let (remain, moved) = split(nodes, used, roots[a], 1, Domain, b, c)
      if remain < 0 or moved < 0: return -1
      roots[a] = remain
      roots[rootCount] = moved
      inc rootCount
    elif item.op == 2:
      roots[a] = mergeNodes(nodes, roots[a], roots[b], 1, Domain)
      roots[b] = 0
    elif item.op == 3:
      packI64(staged, bytes, rangeSum(nodes, roots[a], 1, Domain, b, c))
      bytes += 8
    else:
      packI64(staged, bytes, kth(nodes, roots[a], 1, Domain, item.b))
      bytes += 8
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)
