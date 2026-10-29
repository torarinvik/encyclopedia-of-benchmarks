const MaxN = 16
const MaxQ = 64
const MaxInput = 210

type LctNode = object
  left, right, parent: int
  reversed: bool
  value, sum: int64

proc isAuxRoot(nodes: var array[MaxN, LctNode], x: int): bool =
  let p = nodes[x].parent
  p < 0 or (nodes[p].left != x and nodes[p].right != x)

proc pull(nodes: var array[MaxN, LctNode], x: int) =
  let leftSum = if nodes[x].left < 0: 0'i64 else: nodes[nodes[x].left].sum
  let rightSum = if nodes[x].right < 0: 0'i64 else: nodes[nodes[x].right].sum
  nodes[x].sum = nodes[x].value + leftSum + rightSum

proc toggleReverse(nodes: var array[MaxN, LctNode], x: int) =
  if x < 0: return
  swap(nodes[x].left, nodes[x].right)
  nodes[x].reversed = not nodes[x].reversed

proc push(nodes: var array[MaxN, LctNode], x: int) =
  if not nodes[x].reversed: return
  toggleReverse(nodes, nodes[x].left)
  toggleReverse(nodes, nodes[x].right)
  nodes[x].reversed = false

proc rotate(nodes: var array[MaxN, LctNode], x: int) =
  let p = nodes[x].parent
  let g = nodes[p].parent
  let rightChild = nodes[p].right == x
  let middle = if rightChild: nodes[x].left else: nodes[x].right
  if not isAuxRoot(nodes, p):
    if nodes[g].left == p: nodes[g].left = x else: nodes[g].right = x
  nodes[x].parent = g
  if rightChild:
    nodes[x].left = p
    nodes[p].right = middle
  else:
    nodes[x].right = p
    nodes[p].left = middle
  nodes[p].parent = x
  if middle >= 0: nodes[middle].parent = p
  pull(nodes, p)
  pull(nodes, x)

proc splay(nodes: var array[MaxN, LctNode], x: int) =
  var stack: array[MaxN, int]
  var count = 0
  var y = x
  stack[count] = y
  inc count
  while not isAuxRoot(nodes, y):
    y = nodes[y].parent
    stack[count] = y
    inc count
  while count > 0:
    dec count
    push(nodes, stack[count])
  while not isAuxRoot(nodes, x):
    let p = nodes[x].parent
    if not isAuxRoot(nodes, p):
      let g = nodes[p].parent
      let zigZig = (nodes[p].left == x) == (nodes[g].left == p)
      rotate(nodes, if zigZig: p else: x)
    rotate(nodes, x)

proc access(nodes: var array[MaxN, LctNode], x: int) =
  var last = -1
  var y = x
  while y >= 0:
    splay(nodes, y)
    nodes[y].right = last
    if last >= 0: nodes[last].parent = y
    pull(nodes, y)
    last = y
    y = nodes[y].parent
  splay(nodes, x)

proc makeRoot(nodes: var array[MaxN, LctNode], x: int) =
  access(nodes, x)
  toggleReverse(nodes, x)

proc findRoot(nodes: var array[MaxN, LctNode], x: int): int =
  access(nodes, x)
  push(nodes, x)
  var root = x
  while nodes[root].left >= 0:
    root = nodes[root].left
    push(nodes, root)
  splay(nodes, root)
  root

proc linkNodes(nodes: var array[MaxN, LctNode], u, v: int): int64 =
  if u == v: return 0
  makeRoot(nodes, u)
  if findRoot(nodes, v) == u: return 0
  nodes[u].parent = v
  1

proc cutNodes(nodes: var array[MaxN, LctNode], u, v: int): int64 =
  if u == v: return 0
  makeRoot(nodes, u)
  access(nodes, v)
  if nodes[v].left != u or nodes[u].right >= 0: return 0
  nodes[v].left = -1
  nodes[u].parent = -1
  pull(nodes, v)
  1

proc pathSum(nodes: var array[MaxN, LctNode], u, v: int): int64 =
  makeRoot(nodes, u)
  if findRoot(nodes, v) != u: return -1
  makeRoot(nodes, u)
  access(nodes, v)
  nodes[v].sum

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc link_cut_tree*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                    {.cdecl, exportc: "link_cut_tree".} =
  if input == nil or inputLength < 2 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN.int64 or qValue < 1 or qValue > MaxQ.int64: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(inputLength) != 2 + n + 3 * q: return -1
  for i in 0..<n:
    if input[2 + i] < 0 or input[2 + i] > 1_000_000: return -1
  let operationsAt = 2 + n
  for i in 0..<q:
    let at = operationsAt + 3 * i
    let op = input[at]
    let u = input[at + 1]
    let v = input[at + 2]
    if op < 0 or op > 2 or u < 0 or u >= nValue or v < 0 or v >= nValue: return -1
  let bytes = 8 * q
  if output == nil or int(outputCapacity) < bytes: return -2
  var nodes: array[MaxN, LctNode]
  for i in 0..<n:
    nodes[i].left = -1
    nodes[i].right = -1
    nodes[i].parent = -1
    nodes[i].value = input[2 + i]
    nodes[i].sum = nodes[i].value
  for i in 0..<q:
    let at = operationsAt + 3 * i
    let op = int(input[at])
    let u = int(input[at + 1])
    let v = int(input[at + 2])
    let result = case op
      of 0: linkNodes(nodes, u, v)
      of 1: cutNodes(nodes, u, v)
      else: pathSum(nodes, u, v)
    putI64(output, i * 8, result)
  int64(bytes)
