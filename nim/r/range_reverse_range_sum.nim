const MaxN = 64
const MaxQ = 32
const MaxInput = 163
const NoneNode = MaxN
type
  Node = object
    left, right, size: int
    value, total: int64
    priority: uint64
    reversed: bool
  Operation = object
    kind, left, right: int

proc priorityFor(index: int): uint64 =
  var state = 1'i64
  for _ in 0..index: state = (state * 48271) mod 2147483647
  uint64(state)
proc nodeSize(nodes: array[MaxN, Node], index: int): int =
  if index == NoneNode: 0 else: nodes[index].size
proc nodeSum(nodes: array[MaxN, Node], index: int): int64 =
  if index == NoneNode: 0 else: nodes[index].total
proc higher(nodes: array[MaxN, Node], a, b: int): bool =
  if nodes[a].priority != nodes[b].priority: nodes[a].priority > nodes[b].priority else: a > b
proc pull(nodes: var array[MaxN, Node], index: int) =
  nodes[index].size = 1 + nodeSize(nodes, nodes[index].left) + nodeSize(nodes, nodes[index].right)
  nodes[index].total = nodes[index].value + nodeSum(nodes, nodes[index].left) + nodeSum(nodes, nodes[index].right)
proc reverseNode(nodes: var array[MaxN, Node], index: int) =
  if index == NoneNode: return
  swap(nodes[index].left, nodes[index].right)
  nodes[index].reversed = not nodes[index].reversed
proc push(nodes: var array[MaxN, Node], index: int) =
  if not nodes[index].reversed: return
  reverseNode(nodes, nodes[index].left)
  reverseNode(nodes, nodes[index].right)
  nodes[index].reversed = false
proc split(nodes: var array[MaxN, Node], root, count: int): tuple[first, second: int] =
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
proc merge(nodes: var array[MaxN, Node], left, right: int): int =
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

proc range_reverse_range_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "range_reverse_range_sum".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 0 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  var offset = 2
  if int(length) < 2 + n: return -1
  var nodes: array[MaxN, Node]
  for i in 0..<n:
    let value = input[offset]
    inc offset
    if value < 0 or value > 1_000_000_000: return -1
    nodes[i] = Node(left: NoneNode, right: NoneNode, size: 1, value: value,
                    total: value, priority: priorityFor(i), reversed: false)
  var operations: array[MaxQ, Operation]
  var queryCount = 0
  for i in 0..<q:
    if offset + 3 > int(length): return -1
    let kind = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    offset += 3
    if (kind != 0 and kind != 1) or left < 0 or left > right or right > nValue: return -1
    operations[i] = Operation(kind: int(kind), left: int(left), right: int(right))
    if kind == 1: inc queryCount
  if offset != int(length): return -1
  var root = NoneNode
  for i in 0..<n: root = merge(nodes, root, i)
  var answers: array[MaxQ, int64]
  var answerCount = 0
  for i in 0..<q:
    let op = operations[i]
    let p = split(nodes, root, op.right)
    let m = split(nodes, p.first, op.left)
    if op.kind == 0: reverseNode(nodes, m.second)
    else:
      answers[answerCount] = nodeSum(nodes, m.second)
      inc answerCount
    root = merge(nodes, merge(nodes, m.first, m.second), p.second)
  let bytes = 8 * queryCount
  if output.isNil or int(capacity) < bytes: return -2
  for i in 0..<queryCount: put64(output, 8 * i, answers[i])
  int64(bytes)
