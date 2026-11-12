const Modulus = 998244353'i64
const MaxN = 32
const MaxQ = 32
const MaxNodes = 64
const MaxInput = 195
const NoneNode = -1
type
  Node = object
    left, right, size: int
    value, total, mul, add: int64
    priority: uint64
    reversed: bool
  Operation = object
    kind, left, right, node: int
    mul, add: int64

proc priorityFor(id: int): uint64 =
  var state = 1'i64
  for _ in 0..id: state = (state * 48271) mod 2147483647
  uint64(state)
proc nodeSize(nodes: array[MaxNodes, Node], index: int): int =
  if index == NoneNode: 0 else: nodes[index].size
proc nodeSum(nodes: array[MaxNodes, Node], index: int): int64 =
  if index == NoneNode: 0 else: nodes[index].total
proc higher(nodes: array[MaxNodes, Node], a, b: int): bool =
  if nodes[a].priority != nodes[b].priority: nodes[a].priority > nodes[b].priority else: a > b
proc pull(nodes: var array[MaxNodes, Node], index: int) =
  nodes[index].size = 1 + nodeSize(nodes, nodes[index].left) + nodeSize(nodes, nodes[index].right)
  nodes[index].total = (nodes[index].value + nodeSum(nodes, nodes[index].left) + nodeSum(nodes, nodes[index].right)) mod Modulus
proc affine(nodes: var array[MaxNodes, Node], index: int, mul, add: int64) =
  if index == NoneNode: return
  nodes[index].value = (mul * nodes[index].value + add) mod Modulus
  nodes[index].total = (mul * nodes[index].total + add * int64(nodes[index].size)) mod Modulus
  nodes[index].mul = (mul * nodes[index].mul) mod Modulus
  nodes[index].add = (mul * nodes[index].add + add) mod Modulus
proc reverseNode(nodes: var array[MaxNodes, Node], index: int) =
  if index == NoneNode: return
  swap(nodes[index].left, nodes[index].right)
  nodes[index].reversed = not nodes[index].reversed
proc push(nodes: var array[MaxNodes, Node], index: int) =
  if nodes[index].mul != 1 or nodes[index].add != 0:
    affine(nodes, nodes[index].left, nodes[index].mul, nodes[index].add)
    affine(nodes, nodes[index].right, nodes[index].mul, nodes[index].add)
    nodes[index].mul = 1
    nodes[index].add = 0
  if nodes[index].reversed:
    reverseNode(nodes, nodes[index].left)
    reverseNode(nodes, nodes[index].right)
    nodes[index].reversed = false
proc split(nodes: var array[MaxNodes, Node], root, count: int): tuple[first, second: int] =
  if root == NoneNode: return (NoneNode, NoneNode)
  push(nodes, root)
  if nodeSize(nodes, nodes[root].left) >= count:
    let parts = split(nodes, nodes[root].left, count)
    nodes[root].left = parts.second
    pull(nodes, root)
    return (parts.first, root)
  let parts = split(nodes, nodes[root].right, count - nodeSize(nodes, nodes[root].left) - 1)
  nodes[root].right = parts.first
  pull(nodes, root)
  (root, parts.second)
proc merge(nodes: var array[MaxNodes, Node], left, right: int): int =
  if left == NoneNode: return right
  if right == NoneNode: return left
  if higher(nodes, left, right):
    push(nodes, left)
    nodes[left].right = merge(nodes, nodes[left].right, right)
    pull(nodes, left)
    return left
  push(nodes, right)
  nodes[right].left = merge(nodes, left, nodes[right].left)
  pull(nodes, right)
  right
proc put64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for j in 0..<8: output[offset + j] = uint8((bits shr (8 * j)) and 255'u64)

proc dynamic_sequence_range_affine_range_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "dynamic_sequence_range_affine_range_sum".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 0 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  var offset = 2
  if int(length) < 2 + n: return -1
  var nodes: array[MaxNodes, Node]
  for i in 0..<n:
    let value = input[offset]
    inc offset
    if value < 0 or value >= Modulus: return -1
    nodes[i] = Node(left: NoneNode, right: NoneNode, size: 1, value: value,
                    total: value, mul: 1, add: 0, priority: priorityFor(i), reversed: false)
  var operations: array[MaxQ, Operation]
  var current = n
  var nodeCount = n
  var queryCount = 0
  for i in 0..<q:
    if offset >= int(length): return -1
    let tag = input[offset]
    inc offset
    if tag < 0 or tag > 4: return -1
    var op = Operation(kind: int(tag), left: 0, right: 0, node: NoneNode, mul: 0, add: 0)
    if tag == 0:
      if offset + 2 > int(length): return -1
      let at = input[offset]
      let value = input[offset + 1]
      offset += 2
      if at < 0 or at > int64(current) or current >= MaxNodes or value < 0 or value >= Modulus: return -1
      op.left = int(at)
      op.node = nodeCount
      nodes[nodeCount] = Node(left: NoneNode, right: NoneNode, size: 1, value: value,
          total: value, mul: 1, add: 0, priority: priorityFor(nodeCount), reversed: false)
      inc nodeCount
      inc current
    elif tag == 1:
      if offset >= int(length): return -1
      let at = input[offset]
      inc offset
      if at < 0 or at >= int64(current): return -1
      op.left = int(at)
      dec current
    elif tag == 2 or tag == 4:
      if offset + 2 > int(length): return -1
      let left = input[offset]
      let right = input[offset + 1]
      offset += 2
      if left < 0 or left > right or right > int64(current): return -1
      op.left = int(left)
      op.right = int(right)
      if tag == 4: inc queryCount
    else:
      if offset + 4 > int(length): return -1
      let left = input[offset]
      let right = input[offset + 1]
      let mul = input[offset + 2]
      let add = input[offset + 3]
      offset += 4
      if left < 0 or left > right or right > int64(current) or mul < 0 or mul >= Modulus or add < 0 or add >= Modulus: return -1
      op.left = int(left)
      op.right = int(right)
      op.mul = mul
      op.add = add
    operations[i] = op
  if offset != int(length): return -1
  var root = NoneNode
  for i in 0..<n: root = merge(nodes, root, i)
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for i in 0..<q:
    let op = operations[i]
    let p = split(nodes, root, op.left)
    if op.kind == 0:
      root = merge(nodes, merge(nodes, p.first, op.node), p.second)
      continue
    var middle: int
    var tail: int
    if op.kind == 1:
      let parts = split(nodes, p.second, 1)
      middle = parts.first
      tail = parts.second
      root = merge(nodes, p.first, tail)
      continue
    else:
      let parts = split(nodes, p.second, op.right - op.left)
      middle = parts.first
      tail = parts.second
      if op.kind == 2: reverseNode(nodes, middle)
      elif op.kind == 3: affine(nodes, middle, op.mul, op.add)
      else:
        answers[answerCount] = nodeSum(nodes, middle)
        inc answerCount
    root = merge(nodes, merge(nodes, p.first, middle), tail)
  let bytes = 8 * queryCount
  if output.isNil or int(capacity) < bytes: return -2
  for i in 0..<queryCount: put64(output, 8 * i, answers[i])
  int64(bytes)
